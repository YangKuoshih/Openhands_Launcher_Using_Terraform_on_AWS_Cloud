#!/usr/bin/env python3
"""
AWS SSO Helper - Automates AWS SSO login and profile management
"""

import subprocess
import json
import os
import sys
import time
from pathlib import Path
from typing import List, Tuple, Optional
from configparser import ConfigParser, NoOptionError, NoSectionError
from json import JSONDecodeError
from boto3 import client as boto3_client
from botocore.exceptions import ClientError
from shutil import which


class AWSConfig:
    """Configuration manager for AWS SSO settings"""
    
    def __init__(self, config_file: str = "config.ini"):
        self.config = ConfigParser()
        self.config_file = config_file
        self._load_config()
    
    def _load_config(self):
        """Load configuration from file"""
        if not os.path.exists(self.config_file):
            raise FileNotFoundError(f"Configuration file {self.config_file} not found")
        
        try:
            with open(self.config_file, 'r', encoding='utf-8') as f:
                self.config.read_file(f)
        except (IOError, PermissionError) as e:
            raise RuntimeError(f"Cannot read configuration file {self.config_file}: {e}")
        
        # Validate required sections exist
        if not self.config.has_section('aws'):
            raise ValueError("Missing required [aws] section in config file")
        if not self.config.has_section('paths'):
            raise ValueError("Missing required [paths] section in config file")
    
    @property
    def sso_profile(self) -> str:
        try:
            return self.config.get('aws', 'sso_profile')
        except (NoSectionError, NoOptionError) as e:
            raise ValueError(f"Missing configuration: {e}")
    
    @property
    def sso_start_url(self) -> str:
        try:
            return self.config.get('aws', 'sso_start_url')
        except (NoSectionError, NoOptionError) as e:
            raise ValueError(f"Missing configuration: {e}")
    
    def _get_config_value(self, section: str, key: str, fallback: str) -> str:
        """Helper method to get config values with error handling"""
        try:
            return self.config.get(section, key, fallback=fallback)
        except (NoSectionError, NoOptionError):
            return fallback
    
    @property
    def sso_region(self) -> str:
        return self._get_config_value('aws', 'sso_region', 'us-east-1')
    
    @property
    def default_region(self) -> str:
        return self._get_config_value('aws', 'default_region', 'us-east-1')
    
    @property
    def output_format(self) -> str:
        return self._get_config_value('aws', 'output_format', 'json')
    
    @property
    def aws_folder_name(self) -> str:
        return self._get_config_value('paths', 'aws_folder_name', '.aws')
    
    @property
    def config_file_name(self) -> str:
        return self._get_config_value('paths', 'config_file', 'config')
    
    @property
    def credentials_file_name(self) -> str:
        return self._get_config_value('paths', 'credentials_file', 'credentials')
    
    @property
    def sso_cache_folder(self) -> str:
        return self._get_config_value('paths', 'sso_cache_folder', 'sso/cache')


class AWSPathManager:
    """Manages AWS file paths and directories"""
    
    def __init__(self, aws_config: AWSConfig):
        self.config = aws_config
        self._aws_folder = self._find_aws_folder()
    
    def _find_aws_folder(self) -> Path:
        """Find the AWS configuration folder"""
        home_dir = Path.home()
        aws_folder = home_dir / self.config.aws_folder_name
        
        if not aws_folder.exists():
            try:
                aws_folder.mkdir(parents=True, exist_ok=True)
                # Test write permissions
                test_file = aws_folder / '.test_write'
                test_file.touch()
                test_file.unlink()
            except (PermissionError, OSError) as e:
                raise RuntimeError(f"Cannot create or write to AWS directory {aws_folder}: {e}")
        
        return aws_folder
    
    @property
    def aws_folder(self) -> Path:
        return self._aws_folder
    
    @property
    def config_file(self) -> Path:
        return self._aws_folder / self.config.config_file_name
    
    @property
    def credentials_file(self) -> Path:
        return self._aws_folder / self.config.credentials_file_name
    
    @property
    def sso_cache_dir(self) -> Path:
        return self._aws_folder / self.config.sso_cache_folder


class SSOTokenManager:
    """Manages SSO token retrieval and caching"""
    
    def __init__(self, path_manager: AWSPathManager):
        self.path_manager = path_manager
    
    def get_latest_access_token(self) -> str:
        """Retrieve the latest SSO access token from cache"""
        cache_dir = self.path_manager.sso_cache_dir
        
        if not cache_dir.exists():
            raise FileNotFoundError(f"SSO cache directory not found: {cache_dir}")
        
        cache_files = list(f for f in cache_dir.iterdir() if f.suffix == '.json')
        
        if not cache_files:
            raise FileNotFoundError("No SSO cache files found")
        
        try:
            latest_cache = max(cache_files, key=lambda f: f.stat().st_mtime)
        except OSError as e:
            raise RuntimeError(f"Failed to access cache files: {e}")
        
        try:
            with open(latest_cache, 'r', encoding='utf-8') as f:
                cached_data = json.load(f)
            
            if 'accessToken' not in cached_data:
                raise KeyError("Access token not found in cache file")
            
            return cached_data['accessToken']
        except (JSONDecodeError, KeyError, IOError, OSError) as e:
            raise RuntimeError(f"Failed to read SSO token from cache: {e}")


class AWSProfileManager:
    """Manages AWS CLI profiles"""
    
    def __init__(self, aws_config: AWSConfig, path_manager: AWSPathManager):
        self.aws_config = aws_config
        self.path_manager = path_manager
    
    def update_profile(self, credentials: dict, profile_name: str):
        """Update AWS CLI config and credentials files"""
        # Validate credentials structure
        required_keys = ['accessKeyId', 'secretAccessKey', 'sessionToken']
        missing_keys = [key for key in required_keys if key not in credentials]
        if missing_keys:
            raise ValueError(f"Missing required credential keys: {missing_keys}")
        
        self._update_config_file(profile_name)
        self._update_credentials_file(credentials, profile_name)
        print(f"Updated profile: {profile_name}")
    
    def _update_config_file(self, profile_name: str):
        """Update the AWS config file"""
        config = ConfigParser()
        config_file = self.path_manager.config_file
        
        try:
            if config_file.exists():
                config.read(config_file)
            
            config[f"profile {profile_name}"] = {
                "region": self.aws_config.default_region,
                "output": self.aws_config.output_format,
                "sso_start_url": self.aws_config.sso_start_url,
                "sso_region": self.aws_config.sso_region
            }
            
            with open(config_file, 'w', encoding='utf-8') as f:
                config.write(f)
            
            print(f"Updated config file: {config_file}")
        except (IOError, PermissionError) as e:
            raise RuntimeError(f"Failed to update config file {config_file}: {e}")
    
    def _update_credentials_file(self, credentials: dict, profile_name: str):
        """Update the AWS credentials file"""
        config = ConfigParser()
        credentials_file = self.path_manager.credentials_file
        
        try:
            if credentials_file.exists():
                config.read(credentials_file)
            
            config[profile_name] = {
                "aws_access_key_id": credentials['accessKeyId'],
                "aws_secret_access_key": credentials['secretAccessKey'],
                "aws_session_token": credentials['sessionToken']
            }
            
            with open(credentials_file, 'w', encoding='utf-8') as f:
                config.write(f)
            
            print(f"Updated credentials file: {credentials_file} for profile: {profile_name}")
        except (IOError, PermissionError) as e:
            raise RuntimeError(f"Failed to update credentials file {credentials_file}: {e}")


class AWSSSOManager:
    """Main AWS SSO management class"""
    
    def __init__(self, config_file: str = "config.ini"):
        self.aws_config = AWSConfig(config_file)
        self.path_manager = AWSPathManager(self.aws_config)
        self.token_manager = SSOTokenManager(self.path_manager)
        self.profile_manager = AWSProfileManager(self.aws_config, self.path_manager)
        self._sso_client = None
        self._access_token = None
    
    def login(self):
        """Perform AWS SSO login"""
        print("Initiating AWS SSO login. Please complete the login process in your browser.")
        # Check if AWS CLI is available
        aws_cli_path = which("aws")
        if not aws_cli_path:
            raise RuntimeError("AWS CLI not found. Please install AWS CLI v2")
        
        try:
            subprocess.run(
                [aws_cli_path, "sso", "login", "--profile", self.aws_config.sso_profile], 
                check=True,
                timeout=300
            )
        except subprocess.CalledProcessError as e:
            raise RuntimeError(f"AWS SSO login failed: {e}")
        except subprocess.TimeoutExpired:
            raise RuntimeError("AWS SSO login timed out after 5 minutes")
    
    def _get_sso_client(self):
        """Get or create SSO client"""
        if self._sso_client is None:
            self._sso_client = boto3_client('sso', region_name=self.aws_config.sso_region)
        return self._sso_client
    
    def _get_access_token(self) -> str:
        """Get or retrieve access token"""
        if self._access_token is None:
            self._access_token = self.token_manager.get_latest_access_token()
        return self._access_token
    
    def get_available_roles(self) -> List[Tuple[str, str]]:
        """Get all available roles from SSO"""
        access_token = self._get_access_token()
        sso = self._get_sso_client()
        
        try:
            accounts = sso.list_accounts(accessToken=access_token)
            available_roles = []
            
            for account in accounts['accountList']:
                try:
                    roles = sso.list_account_roles(
                        accessToken=access_token,
                        accountId=account['accountId']
                    )
                    
                    for role in roles['roleList']:
                        available_roles.append((account['accountId'], role['roleName']))
                    # Add small delay to avoid rate limiting
                    time.sleep(0.1)
                except ClientError as e:
                    print(f"Warning: Failed to get roles for account {account['accountId']}: {e}")
                    continue
            
            return available_roles
        except Exception as e:
            raise RuntimeError(f"Failed to get available roles: {e}")
    
    def setup_profiles(self, available_roles: List[Tuple[str, str]]) -> List[str]:
        """Set up AWS CLI profiles for all available roles"""
        access_token = self._get_access_token()
        sso = self._get_sso_client()
        
        profile_names = []
        
        for account_id, role_name in available_roles:
            try:
                credentials = sso.get_role_credentials(
                    roleName=role_name,
                    accountId=account_id,
                    accessToken=access_token
                )['roleCredentials']
                
                if credentials:
                    print(f"Got credentials for Account ID: {account_id}, Role: {role_name}")
                    profile_name = f"sso-{account_id}-{role_name}"
                    profile_names.append(profile_name)
                    self.profile_manager.update_profile(credentials, profile_name)
            
            except Exception as e:
                print(f"Failed to get credentials for {account_id}/{role_name}: {e}")
        
        return profile_names
    
    def display_console_urls(self, available_roles: List[Tuple[str, str]]):
        """Display direct console URLs"""
        print("\nDirect URLs to the console:")
        print()
        for account_id, role_name in available_roles:
            url = f"{self.aws_config.sso_start_url}/#/console?account_id={account_id}&role_name={role_name}"
            print(url)
    
    def display_profile_commands(self, profile_names: List[str]):
        """Display commands to set AWS profiles"""
        if not profile_names:
            return
            
        print("\nAvailable profiles:")
        for i, profile_name in enumerate(profile_names, 1):
            print(f"{i}. {profile_name}")
        
        print("\nSelect default profile (or press Enter to skip):")
        try:
            choice = input("Enter number (1-{0}): ".format(len(profile_names))).strip()
            
            if choice and choice.isdigit():
                index = int(choice) - 1
                if 0 <= index < len(profile_names):
                    selected_profile = profile_names[index]
                    self._set_default_profile(selected_profile)
                    print(f"\nDefault profile set to: {selected_profile}")
                else:
                    print("Invalid selection. No default profile set.")
            else:
                print("No default profile set.")
        except (KeyboardInterrupt, EOFError):
            print("\nNo default profile set.")
        
        print("\nManual profile commands:")
        for profile_name in profile_names:
            if os.name == 'nt':  # Windows
                print(f"set AWS_DEFAULT_PROFILE={profile_name}")
            else:  # Linux/macOS
                print(f"export AWS_DEFAULT_PROFILE={profile_name}")
    
    def _set_default_profile(self, profile_name: str):
        """Set the default AWS profile in credentials file"""
        config = ConfigParser()
        credentials_file = self.path_manager.credentials_file
        
        try:
            if credentials_file.exists():
                config.read(credentials_file)
            
            # Copy selected profile to [default] section
            if profile_name in config:
                config['default'] = dict(config[profile_name])
                
                with open(credentials_file, 'w', encoding='utf-8') as f:
                    config.write(f)
                
                print(f"Updated [default] profile with {profile_name} credentials")
            else:
                print(f"Profile {profile_name} not found")
                
        except (IOError, PermissionError) as e:
            print(f"Failed to set default profile: {e}")
    
    def run(self):
        """Main execution method"""
        try:
            self.login()
            # Reset cached token after login to ensure fresh token
            self._access_token = None
            available_roles = self.get_available_roles()
            profile_names = self.setup_profiles(available_roles)
            
            self.display_console_urls(available_roles)
            self.display_profile_commands(profile_names)
            
        except (ClientError, RuntimeError, ValueError, FileNotFoundError) as e:
            print(f"An error occurred: {e}")
            sys.exit(1)
        except KeyboardInterrupt:
            print("\nOperation cancelled by user")
            sys.exit(1)


def main():
    """Main entry point"""
    try:
        config_file = sys.argv[1] if len(sys.argv) > 1 else "config.ini"
        sso_manager = AWSSSOManager(config_file)
        sso_manager.run()
    except (FileNotFoundError, ValueError, RuntimeError, ClientError) as e:
        print(f"Error: {e}")
        sys.exit(1)
    except KeyboardInterrupt:
        print("\nOperation cancelled by user")
        sys.exit(1)


if __name__ == "__main__":
    main()