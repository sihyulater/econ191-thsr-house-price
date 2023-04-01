import requests
import json
import redis
import pandas as pd
import os
from urllib.parse import urlencode

# caching
redis_client = redis.Redis(host = 'localhost', port = 6379, db = 0)

api_key = "AIzaSyDdsRHFQqxDJnLkSysPuBKpS6sz9eNsayU"

def fetch_place(address, update:bool = False):
    """
    takes in an address and get the json data of the place. If not found in cache then would 
    call the google map API to fetch data.
    """
    
    place_key = f"{address}_place"
    place = redis_client.get(place_key)
    
    if update:
        place = None
    
    if not place:
        print('Could not find place in cache. Retrieving from Google Maps API...')
        endpoint = f"https://maps.googleapis.com/maps/api/geocode/json"
        params = {"address": address, "key": api_key}
        url_params = urlencode(params)
        url = f"{endpoint}?{url_params}"
        r = requests.get(url)
        if r.status_code not in range(200, 299):
            place = {}
        else:
            place = r.json()['results'][0]
        
        redis_client.set(place_key, json.dumps(place))
    
    else:
        print('Found place in cache, serving from redis...')
        place = json.loads(place)
        
    return place

def extract_lat_lng(address, update=False):
    
    place = fetch_place(address)[0]
    location = place['geometry']['location']
    lat, lng = location['lat'], location['lng']
    
    return lat, lng


# === sample === #
sample = '宜蘭縣宜蘭市農權路三段２７巷７號'
my_place = extract_lat_lng(sample)
print(my_place)

# === looping through all === #
df = pd.read_csv('11Input/02DataProcessed/sample.csv')
df.head()
