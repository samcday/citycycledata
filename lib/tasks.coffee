sugar = require "sugar"
mongoose = require "mongoose"

mongoose.connect process.env.MONGOLAB_URI or "mongodb://localhost/citycycle"

cleanup = () ->
	mongoose.disconnect()
	process.exit 0

mongoose.connection.on "open", () ->
	switch process.argv[2]
    	when "stations" then require("./tasks/scrape_stations") cleanup
    	when "status" then require("./tasks/scrape_statuses") cleanup
