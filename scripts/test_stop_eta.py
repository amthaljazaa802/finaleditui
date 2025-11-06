import requests
import json

url = 'http://127.0.0.1:8000/api/bus-lines/3/stops-with-eta/?bus_id=4'
print(f'Testing: {url}\n')

try:
    r = requests.get(url, timeout=5)
    if r.status_code == 200:
        data = json.loads(r.text)
        print(f"ETA Source: {data.get('eta_source')}")
        print(f"Speed: {data.get('speed_kmh')} km/h")
        
        if 'current_segment' in data:
            seg = data['current_segment']
            print(f"Current Segment: {seg.get('from_stop')} -> {seg.get('to_stop')} ({seg.get('progress')}%)\n")
        
        print("=== ALL STOPS WITH ETA ===")
        for i, s in enumerate(data['stops'][:10]):
            eta_sec = s.get('eta_seconds')
            dist = s.get('distance_meters')
            passed = s.get('passed')
            if eta_sec:
                eta_min = eta_sec / 60
                print(f"Stop {i+1} - {s['stop_name']}: {eta_sec}s ({eta_min:.1f}min), Distance: {dist}m, Passed: {passed}")
            else:
                print(f"Stop {i+1} - {s['stop_name']}: No ETA (Passed: {passed})")
    else:
        print(f'Error: {r.status_code}')
except Exception as e:
    print(f'Error: {e}')
