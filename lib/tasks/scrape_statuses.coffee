async = require "async"
jsdom = require "jsdom"
url = require "url"
request = require "request"

constants = require "../constants"

Station = require "../model/Station"
StationStatus = require "../model/StationStatus"

module.exports = (cleanup) ->
    currentHour =new Date().getHours() 
    if currentHour < 5 or currentHour >= 22
        console.log "Skipping station status scrape as it's not between the hours of 5am - 10pm"
        return cleanup()

    Station.find {}, ["number"], (err, stations) ->
        console.log "Scraping data for #{stations.length} stations."

        iterator = (station, cb) ->
            console.log "Scraping station #{station.number}"

            request.get
                url: "#{constants.baseURL}stationdetails/brisbane/#{station.number}"
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

            cleanup()