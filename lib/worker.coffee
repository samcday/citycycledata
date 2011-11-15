sugar = require "sugar"
jsdom = require "jsdom"
request = require "request"
mongoose = require "mongoose"
url = require "url"
async = require "async"
cron = require "cron"

Station = require "./model/Station"
StationStatus = require "./model/StationStatus"

baseURL = "http://www.citycycle.com.au/service/"

mongoose.connect process.env.MONGOLAB_URI or "mongodb://localhost/citycycledata"

scrapeStations = () ->
    Station.find {}, ["number"], (err, stations) ->
        console.log "Scraping data for #{stations.length} stations."

        iterator = (station, cb) ->
            console.log "Scraping station #{station.number}"

            request.get
                url: "#{baseURL}stationdetails/brisbane/#{station.number}"
            , (err, res, body) ->
                if err?
                    console.error "HTTP error while scraping station ##{station.number}: ", err
                    return cb()

                doc = jsdom.jsdom body

                availableEl = doc?.getElementsByTagName?("available")?[0]
                freeEl = doc?.getElementsByTagName?("free")?[0]
                totalEl = doc?.getElementsByTagName?("total")?[0]

                if not availableEl or not freeEl or not totalEl
                    console.error "Malformed response for station ##{station.number}: ", err
                    return cb()



                stationStatus = new StationStatus

                stationStatus.station = station._id
                stationStatus.available = parseInt availableEl.innerHTML
                stationStatus.free = parseInt freeEl.innerHTML
                stationStatus.total = parseInt totalEl.innerHTML
                stationStatus.ticket = doc?.getElementsByTagName?("ticket")?[0] ? true : false


                # If there's no available spots, used spots, or spots at all, then the station is
                # still closed, don't bother saving the data.
                if stationStatus.available is 0 and stationStatus.free is 0 and stationStatus.total is 0
                    return cb()


                stationStatus.save (err) ->
                    return cb err if err?
                    console.log "Saved new sample for station ##{station.number}"
                    cb()

        async.forEachSeries stations, iterator, (err) ->
            if err?
                console.error "Error during station data scrape.", err
            else
                console.log "Station data scrape complete."

scrapeStationList = () ->
    console.log "Scraping station list."

    request.get
        url: "#{baseURL}carto"
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

# Run between the hours of 5am - 10pm.
cron.CronJob "0 */10 5-21 * * *", scrapeStations
cron.CronJob "0 0 22 * * *", scrapeStations

cron.CronJob "0 0 0 * * *", scrapeStationList