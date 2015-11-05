/*
  Copyright (C) 2015 Alexander Ladygin
  Contact: Alexander Ladygin <fake.ae@gmail.com>
  All rights reserved.

  This file is part of Harbour-vk-music.

  Harbour-vk-music is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  Harbour-vk-music is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Harbour-vk-music.  If not, see <http://www.gnu.org/licenses/>.
*/
.pragma library

var API_SERVER_URL = "https://api.vk.com/method";
var API_VERSION = "5.37";
var DEFAULT_PAGE_SIZE = 30;
var DEFAULT_REQUEST_TIMEOUT = 20000;
var TIME_OUT_RESPONSE = "__TIME_OUT__";

function createAPIRequestWithTimeout(query, callBackFunction, parent, asynchronous){
    asynchronous = (typeof asynchronous !== 'undefined' ? asynchronous : true);

    var request = new XMLHttpRequest();

    var timer = Qt.createQmlObject(
                    "import QtQuick 2.0;"
                        + "Timer {interval: " + DEFAULT_REQUEST_TIMEOUT + "; repeat: false; running: true;}"
                    , parent
                    , "timeoutTimer"
                );
    timer.triggered.connect(function(){
        request.abort();
        callBackFunction(TIME_OUT_RESPONSE);
    });

    request.onreadystatechange = function() {
        if (request.readyState === XMLHttpRequest.DONE) {
            timer.stop();
//            console.log("response = " + request.responseText);
            callBackFunction(request.responseText);
        }
    }

    request.open("GET", query, asynchronous);
    request.send();
}

function getAudioList(parent, accessToken, userId, parseAPIResponse_getList, offset, pageSize, searchFilter, albumId) {
    console.log("getAudioList started");
    console.log("searchFilter = " + searchFilter);

    var query;

    //default values
    pageSize = (typeof pageSize !== 'undefined' ? pageSize : DEFAULT_PAGE_SIZE);
    offset = (typeof offset !== 'undefined' ? offset : 0);
    albumId = (typeof albumId !== 'undefined' ? albumId : -1);

    if (searchFilter){
        query = API_SERVER_URL
            + "/audio.search?"
            + "v=" + API_VERSION
            + "&access_token=" + accessToken
            + "&count=" + pageSize
            + "&offset=" + offset
            + "&q=" + searchFilter
            + "&auto_complete=0"
            + "&sort=2"
            + "&search_own=1"
        ;
    } else {
        query = API_SERVER_URL
            + "/audio.get?"
            + "v=" + API_VERSION
            + "&access_token=" + accessToken
            + "&count=" + pageSize
            + "&offset=" + offset
            + "&album_id=" + albumId
        ;
    }

    console.log("query = " + query);

    createAPIRequestWithTimeout(query, parseAPIResponse_getList, parent);
}

function addAudio(parent, accessToken, aid, owner_id, parseAPIResponse_add){
    console.log("addAudio started");
    console.log("aid = " + aid);
    console.log("owner_id = " + owner_id);

    var query = API_SERVER_URL
        + "/audio.add?"
        + "v=" + API_VERSION
        + "&access_token=" + accessToken
        + "&audio_id=" + aid
        + "&owner_id=" + owner_id
    ;

    console.log("query = " + query);

    createAPIRequestWithTimeout(query, parseAPIResponse_add, parent);
}

function removeAudio(parent, accessToken, aid, owner_id, parseAPIResponse_remove){
    console.log("removeAudio started");
    console.log("aid = " + aid);
    console.log("owner_id = " + owner_id);

    var query = API_SERVER_URL
        + "/audio.delete?"
        + "v=" + API_VERSION
        + "&access_token=" + accessToken
        + "&audio_id=" + aid
        + "&owner_id=" + owner_id
    ;

    console.log("query = " + query);

    createAPIRequestWithTimeout(query, parseAPIResponse_remove, parent);
}

function getAlbums(parent, accessToken, owner_id, parseAPIResponse_getAlbums, offset, pageSize){
    console.log("getAlbums started");

    pageSize = (typeof pageSize !== 'undefined' ? pageSize : DEFAULT_PAGE_SIZE);
    offset = (typeof offset !== 'undefined' ? offset : 0);

    var query = API_SERVER_URL
        + "/audio.getAlbums?"
        + "v=" + API_VERSION
        + "&access_token=" + accessToken
        + "&owner_id=" + owner_id
        + "&count=" + pageSize
        + "&offset=" + offset
    ;

    console.log("query = " + query);

    createAPIRequestWithTimeout(query, parseAPIResponse_getAlbums, parent);
}

function getCount(parent, accessToken, owner_id, parseAPIResponse_getCount){
    console.log("getAlbums started");

    var query = API_SERVER_URL
        + "/audio.getCount?"
        + "v=" + API_VERSION
        + "&access_token=" + accessToken
        + "&owner_id=" + owner_id
    ;

    console.log("query = " + query);

    createAPIRequestWithTimeout(query, parseAPIResponse_getCount, parent);
}

function getLyrics(parent, accessToken, owner_id, parseAPIResponse_getLyrics, lyrics_id){
    console.log("getAlbums started");

    var query = API_SERVER_URL
        + "/audio.getLyrics?"
        + "v=" + API_VERSION
        + "&access_token=" + accessToken
        + "&lyrics_id=" + lyrics_id
    ;

    console.log("query = " + query);

    createAPIRequestWithTimeout(query, parseAPIResponse_getLyrics, parent);
}
