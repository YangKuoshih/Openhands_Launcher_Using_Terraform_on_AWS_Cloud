import requests
import uuid
import time
import subprocess
import sys
import json

BASE_URL = "http://localhost:8150"

def run_command(command):
    try:
        result = subprocess.run(command, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"Error running command '{command}': {e.stderr}")
        return None

def test_conversation_start():
    print("=== Starting OpenHands Conversation Test ===")
    
    # 1. Check if Server is up
    try:
        print(f"Checking server status at {BASE_URL}...")
        resp = requests.get(f"{BASE_URL}/api/options/config")
        if resp.status_code == 200:
            print("✅ Server is reachable.")
        else:
            print(f"❌ Server returned status {resp.status_code}")
            return False
    except Exception as e:
        print(f"❌ Failed to connect to server: {e}")
        return False

    # 2. Generate Conversation ID
    conversation_id = str(uuid.uuid4())
    print(f"Generated Conversation ID: {conversation_id}")

    # 3. Start Conversation (simulating frontend)
    # Based on logs, the frontend posts to /api/conversations/{id}/start ?? 
    # Or maybe just connecting via socket triggers it?
    # Let's try to hit the REST endpoints we saw in logs.
    
    # Actually, usually creating a conversation might be a POST to /api/conversations
    # But logs showed: POST /api/conversations/{id}/start
    
    start_url = f"{BASE_URL}/api/conversations/{conversation_id}/start"
    print(f"Attempting to start conversation via API: {start_url}")
    
    # We might need a dummy token or something, but logs showed "No provider tokens fetched" so maybe not needed for basic start.
    try:
        # The logs showed a POST to start
        resp = requests.post(start_url, json={"arg": "test"}) # Payload might matter, sending empty or dummy
        print(f"Start API Response: {resp.status_code} - {resp.text}")
    except Exception as e:
        print(f"⚠️ API call failed (might be expected if it relies on socket): {e}")

    # 4. Wait and Check for Runtime Container
    print("Waiting 10 seconds for runtime container to spawn...")
    time.sleep(10)

    print("Checking for runtime containers...")
    # Look for containers with 'openhands-runtime' or 'oca-agent' in name
    # The logs showed 'oca-agent-...'
    
    containers = run_command("docker ps -a --format '{{.Names}} {{.Status}} {{.Image}}'")
    print("Current Containers:")
    print(containers)
    
    runtime_container = None
    for line in containers.split('\n'):
        if "oca-agent" in line or "openhands-runtime" in line:
            parts = line.split()
            name = parts[0]
            status = " ".join(parts[1:-1]) # rough parsing
            image = parts[-1]
            
            # Check if it matches our conversation ID (roughly)
            # The container name usually contains the conversation ID
            if conversation_id.replace("-", "") in name or conversation_id in name:
                runtime_container = name
                print(f"✅ Found runtime container for this session: {name}")
                print(f"   Status: {status}")
                print(f"   Image: {image}")
                break
    
    if not runtime_container:
        # Fallback: check most recent oca-agent
        print("⚠️ Specific runtime container not found by ID. Checking most recent 'oca-agent' container...")
        recent = run_command("docker ps -a --filter 'name=oca-agent' --format '{{.Names}}' | head -n 1")
        if recent:
            runtime_container = recent
            print(f"Found most recent runtime container: {runtime_container}")
        else:
            print("❌ No runtime containers found.")
            return False

    # 5. Inspect Logs
    print(f"Inspecting logs for container: {runtime_container}")
    logs = run_command(f"docker logs {runtime_container} 2>&1")
    
    if logs:
        print("--- Runtime Container Logs (Last 20 lines) ---")
        print("\n".join(logs.split('\n')[-20:]))
        print("----------------------------------------------")
        
        if "micromamba: no such file or directory" in logs:
            print("❌ FAILURE: Found micromamba error in logs!")
            return False
        elif "OCI runtime create failed" in logs:
             print("❌ FAILURE: Container failed to start (OCI runtime error)!")
             return False
        else:
            print("✅ No obvious startup errors found in logs.")
            return True
    else:
        print("⚠️ Could not fetch logs (maybe container is gone or empty?)")
        # If container exited with 1, it failed.
        inspect = run_command(f"docker inspect {runtime_container} --format '{{{{.State.ExitCode}}}}'")
        if inspect and inspect.strip() != "0":
             print(f"❌ Container exited with code {inspect.strip()}")
             return False
        return True

if __name__ == "__main__":
    success = test_conversation_start()
    sys.exit(0 if success else 1)
