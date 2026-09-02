import requests
import os

# Configuration
CLIENT_ID = 'vxqnGNRz0aQ6eY_SdMST1IxAoLfB3qTtfnbSBIDA92o'
QUERY = 'pastel purple fluid gradient'
COUNT = 20
FOLDER_NAME = 'lavender_wallpapers'

def download_wallpapers():
    print(f"Searching for '{QUERY}' wallpapers...")
    url = f"https://api.unsplash.com/photos/random?query={QUERY}&count={COUNT}&orientation=landscape&client_id={CLIENT_ID}"
    
    response = requests.get(url)

    if response.status_code == 200:
        images = response.json()
        os.makedirs(FOLDER_NAME, exist_ok=True)

        for i, img in enumerate(images):
            img_url = img['urls']['full']
            print(f"Downloading image {i+1} of {COUNT}...")
            
            img_data = requests.get(img_url).content
            file_path = os.path.join(FOLDER_NAME, f'wallpaper_{i+1}.jpg')
            
            with open(file_path, 'wb') as handler:
                handler.write(img_data)
                
        print("\nSuccess! All 20 wallpapers have been downloaded.")
    else:
        print(f"Error {response.status_code}: Please check your API key and connection.")

if __name__ == '__main__':
    download_wallpapers()
