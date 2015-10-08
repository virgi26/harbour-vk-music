/*
  Copyright (C) 2015 Petr Vytovtov
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

.import QtQuick.LocalStorage 2.0 as LocalStorage

var _db;

function _getDatabase(){
    if (!_db){
        _db = LocalStorage.LocalStorage.openDatabaseSync("harbour-vk-music", "1.0", "Data", 100000);
        _initDatabase();
    }

    return _db;
}

function _initDatabase() {
    console.log("initDatabase started");

    //creating tables
    _db.transaction( function (tx) {
            tx.executeSql("create table if not exists properties (key TEXT primary key, value TEXT)");
        }
    );
    console.log("initDatabase finished");
}

function getProperty(propertyName){
    console.log("getProperty started: " + propertyName);
    var db = _getDatabase();
    var retValue;

    db.readTransaction(
                function (tx) {
                    var queryResults = tx.executeSql("select value from properties where key = ?", [propertyName]);

                    if (queryResults.rows.length != 1) {//propery not found
                        return "";
                    }

                    retValue = queryResults.rows.item(0).value;
                    console.log("getProperty value: " + retValue);
                }
    );

    if (retValue){
        return retValue;
    } else {
        return "";
    }

}

function setProperty(propertyName, propertyValue){
    console.log("setProperty started: " + propertyName + " = " + propertyValue);
    var db = _getDatabase();

    db.transaction(
                function (tx){
                    tx.executeSql("DELETE FROM properties where key = ?", [propertyName]);
                    tx.executeSql("INSERT INTO properties (key, value) VALUES (?, ?)", [propertyName, propertyValue]);
                }
    );
}
