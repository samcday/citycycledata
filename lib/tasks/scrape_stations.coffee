async = require "async"
jsdom = require "jsdom"
url = require "url"
request = require "request"

constants = require "../constants"

Station = require "../model/Station"
StationStatus = require "../model/StationStatus"

module.exports = (cleanup) ->
    console.log "Scraping station list."

    request.get
        url: "#{constants.baseURL}carto"
    , (err, res, body) ->
        if err?
            console.error "HTTP error while scraping station list: ", err
            return

        console.log "Scraped station list."
        doc = jsdom.jsdom body
        markers = doc?.getElementsByTagName?("markers")?[0]

        return console.error "Malformed response from station list." if not markers

        console.log "#{markers.children.length} stations."

        async.forEachSeries markers.children, (marker, cb) ->
            stationNumber = marker.getAttribute "number"

            Station.findOne { number: stationNumber }, (err, doc) ->
                return cb err if err?
                return cb() if doc?

                console.log "Creating a new station (number #{stationNumber})"

                newStation = new Station
                newStation.name = marker.getAttribute "name"
                newStation.number = stationNumber
                newStation.address = marker.getAttribute "address"
                newStation.fullAddress = marker.getAttribute "fullAddress"
                newStation.lat = marker.getAttribute "lat"
                newStation.long = marker.getAttribute "lng"
                newStation.open = marker.getAttribute "open" ? true : false
                newStation.bonus = marker.getAttribute "bonus" ? true : false

                newStation.save (err) ->
                    return cb err if err?
                    console.log "New station ##{newStation.number} created."
                    cb()
        , (err) ->
            if err?
                console.error "Error during station list scrape.", err
            else
                console.log "Station list scrape complete."

            cleanup()