from django.shortcuts import render
from django.http import HttpResponse, JsonResponse
import spotipy
import base64
import requests

import os
import json
from dateutil.utils import today
from spotipy.oauth2 import SpotifyOAuth, SpotifyClientCredentials
from django.views.decorators.csrf import csrf_exempt

import socket
from threading import Thread
import threading
import time

import socket

def send_data(data):
    HOST = "172.20.10.4"
    PORT = 6005
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.connect((HOST, PORT))
        s.sendall(data.encode())


CLIENT_ID='c287f4b6bc874c2ab63169028d5aedc1'
CLIENT_SECRET='81f3641081dc4e50bc950346f1c2562a'
SPOTIPY_REDIRECT_URI = 'http://localhost:8080'
SCOPE = "user-modify-playback-state playlist-modify-public user-read-currently-playing"
CACHE = '.spotipyoauthcache'

songList = []
upNext = None
upNow = None

global Timer
global sp
global user_id
global access_token

class Song:
    def __init__(self, uri, title, artist, duration, cover, votes, progress):
        self.uri = uri
        self.title = title
        self.artist = artist
        self.duration = duration
        self.cover = cover
        self.votes = 0
        self.progress = progress

def startTimer():
    Timer = 120
    return

CLIENT_ID            = 'c287f4b6bc874c2ab63169028d5aedc1'
CLIENT_SECRET        = '81f3641081dc4e50bc950346f1c2562a'
SPOTIPY_REDIRECT_URI = 'http://172.20.10.4:8000/auxing/authenticate/'
TOKEN_URL            = 'https://accounts.spotify.com/api/token'

'''
https://accounts.spotify.com/authorize?response_type=code&client_id=c287f4b6bc874c2ab63169028d5aedc1&scope=user-modify-playback-state playlist-modify-public user-read-currently-playing&redirect_uri=http://172.20.10.4:8000/auxing/authenticate/&state=5
'''
@csrf_exempt
def authenticate(request):
    if request.method == "GET":    
        auth_token = request.GET['code']

        auth_header = base64.urlsafe_b64encode((CLIENT_ID + ':' + CLIENT_SECRET).encode())
        headers = {
            'Content-Type': 'application/x-www-form-urlencoded',
            'Authorization': 'Basic %s' % auth_header.decode()
        }

        payload = {
            'grant_type': 'authorization_code',
            'code': auth_token,
            'redirect_uri': SPOTIPY_REDIRECT_URI,
        }

        access_token_request       = requests.post(url=TOKEN_URL, data=payload, headers=headers)
        access_token_response_data = access_token_request.json()
        access_token               = access_token_response_data['access_token']
        
        global sp
        sp = spotipy.Spotify(auth=access_token)                        

        #print(access_token)
        print("AUTHORIZED BB")
        sendList()
        return HttpResponse("WEEEEEEE")



# Create your views here.
@csrf_exempt
def index(request):
    return HttpResponse("Sup bitches")

@csrf_exempt
def poopoo(request):
    #print(request.method)
    if request.method == "POST":
        print(request.POST['fname'])
    return render(request,'poopoo.html',{})

@csrf_exempt
def sendTable(request):
    # if request.method == "GET":

    return HttpResponse()


#GET takes in a search query, and returns a list of options of songs
#POST takes in a song json and adds it to the list
@csrf_exempt
def search(request):
    print("SEARCHING FOR SONGS")
    global sp
    if not sp:
        return HttpResponse("sad days")

    if request.method == "POST":
        searchString = request.POST['thing']
        if len(searchString) == 0:
            return HttpResponse("sad days")
        items = sp.search(searchString, type='track', limit=5)['tracks']['items']
        results = []
          
        for item in items:
            #sp.add_to_queue(item['uri'])
            result = {'uri': item['uri'], 'title': item['name'], 'artist': item['artists'][0]['name'], 'duration': float(item['duration_ms']) / 1000,
                  'album_cover': item['album']['images'][0]['url'], 'votes' : 0}
            results.append(result)
        jsonResults = json.dumps(results)

        #print(searchString)
        #print(jsonResults)
        #do the spotipy query from before here
        #convert the results to a json 
        #send the top 5 back and render in search bar
        return HttpResponse(jsonResults)
    # elif request.method == "POST": 
    #     print(request.POST)
    #     song = request.POST
    #     song = Song(song['uri'], song['title'], song['artist'], song['duration'], song['album_cover'])
    #     if len(songList) == 0 and not sp.currently_playing():
    #         sp.start_playback(song.URI)
    #         return HttpResponse("Song immediately played")
    #     # startTimer()
    #     songList.append(song)
    #     # refresh()
    #     return HttpResponse("Song Added to List")
        #Add the object to the list
    return render(request, 'search.html', {})



# Redundant, since a GET to search will return options, and a POST will add the song to the list
@csrf_exempt
def addToList(request):
    if request.method == "POST":
        print("ADDING TO THE LIST WEEOWOOWEOWOEOWE")
        songstring = request.POST['json']
        songJson = json.loads(songstring)
        song = Song(songJson['uri'], songJson['title'], songJson['artist'], songJson['duration'], songJson['album_cover'], 0, 0)
        if len(songList) == 0 and (sp.currently_playing() is None or sp.currently_playing()['is_playing'] is False):
            try:
                sp.start_playback(song.uri)
                time.sleep(0.1)
                print("SONG IMMEDIATELY PLAYED")
                return HttpResponse("Song immediately played")
            except:
                print("DEVICE INACTIVE")
                return HttpResponse("Alert! Device Inactive. Please resume playback from your spotify app.")
        if len(songList) == 0:
            global t1
            t1 = Thread(target=timer)
            t1.start()
        for s in songList:
            if s.uri == song.uri:
                return HttpResponse("Already Added")
        # startTimer()  
        songList.append(song)
        # refresh()
        sendList()
        return HttpResponse("Song Added to List")
        #Add the object to the list
    return render(request, 'addToList.html', {})

@csrf_exempt
def vote(request):
    if request.method == "POST":
        uri = request.POST['uri']
        vote = int(request.POST['vote'])
        
        for song in songList:
            if (song.uri == uri):
                print("BEFORE VOTING:")
                print(song.votes)
                song.votes += vote
                
        print("AFTER VOTING")
        print(songList)
        sendList()
        return HttpResponse("Voted!")    

@csrf_exempt
def getList(request):
    print("getting list")
    if request.method == "GET":
        songList.sort(key=lambda x: x.votes, reverse=True)
        jsonList = songsToJSON(songList)
        print("Got list")
        return HttpResponse(jsonList)


def JSONtoSong(songJson):
    song = Song(songJson['item']['uri'], songJson['item']['name'], songJson['item']['artists'][0]['name'], float(songJson['item']['duration_ms']) / 1000, songJson['item']['album']['images'][0]['url'], 0, float(songJson['progress_ms']) / 1000)
    return song

def songsToJSON(songs):
    jsonObj = []
    for song in songs:
        result = {'uri': song.uri, 'title': song.title, 'artist': song.artist, 'duration': song.duration, 'album_cover': song.cover, 'votes': song.votes, 'progress':song.progress}
        jsonObj.append(result)
    return json.dumps(jsonObj)
        
@csrf_exempt
def sendList():
    global songList
    songList.sort(key=lambda x: x.votes, reverse=True)
    currSong = sp.currently_playing()
    if currSong:
        currSong = JSONtoSong(currSong)
        for song in songList:
            if song.uri == currSong.uri:
                songList.remove(song)
        songList.append(currSong)
    print(songList)
    jsonList = songsToJSON(songList)
    send_data(jsonList)
    songList = songList[:-1]


        # NEEDS TO SEND UPDATE TO ALL OF THE OTHER DEVICES
        #song_title = request.POST{"uri": "spotify:track:1c8gk2PeTE04A1pIDH9YMk", "title": "Rolling in the Deep", "artist": "Adele", "duration": 228.093, "album_cover": "https://i.scdn.co/image/ab67616d0000b2732118bf9b198b05a95ded6300"}

# def timedAction():
#     time.sleep(30)
#     return 

@csrf_exempt
def timer():
    while True:
        print("Gabagool")
        if not sp:
            print("DEEP DEPRESSION")
            time.sleep(10)
            continue

        #Here we have the auth
        currSong = sp.currently_playing()
        if currSong:
            timeLeft = (float(currSong['item']['duration_ms']) - float(currSong['progress_ms'])) / 1000
        else:
            continue

        sendList()

        print(f"TIME LEFT :   {timeLeft}")

        if timeLeft < 15:  #lock in the next song here
            songList.sort(key=lambda x: x.votes, reverse=True)
            if len(songList) != 0:    
                upNext = songList[0]
                print(upNext.title)
                songList.pop(0)
                sp.add_to_queue(upNext.uri)
                time.sleep(timeLeft+3)
                sendList()
            else:
                return
        else:
            time.sleep(1)

        #if something is playing, get the time left
        # if less than 10 seconds, queue right away
        #otherwise set a wait for the remaining time - 15 seconds, and then quueue
        #When you queue, lock it in

        print("hi")

        

