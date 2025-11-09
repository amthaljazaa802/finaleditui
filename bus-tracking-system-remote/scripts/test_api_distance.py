import requests
import json

url = 'http://127.0.0.1:8000/api/bus-lines/3/stops-with-eta/?bus_id=4'
print(f'Testing API: {url}\n')

try:
    r = requests.get(url, timeout=5)
    print(f'Status: {r.status_code}')
    
    if r.status_code == 200:
        data = json.loads(r.text)
        print(f'\nETA Source: {data.get("eta_source")}')
        print(f'Speed: {data.get("speed_kmh")} km/h')
        
        if 'current_segment' in data:
            seg = data['current_segment']
            print(f'Current Segment: {seg.get("from_stop")} -> {seg.get("to_stop")} ({seg.get("progress")}% complete)')
        
        print(f'\nFirst 5 stops:')
        for s in data['stops'][:5]:
            eta = s.get('eta_seconds')
            dist = s.get('distance_meters')
            passed = s.get('passed')
            print(f'  {s["stop_name"]}: ETA={eta}s ({eta/60:.1f}min), Distance={dist}m, Passed={passed}')
    else:
        print(f'Error: {r.text[:500]}')
except Exception as e:
    print(f'Error: {e}')
