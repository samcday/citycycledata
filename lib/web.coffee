require "sugar"
express = require "express"
path = require "path"
mongoose = require "mongoose"
async = require "async"

mongoose.connect process.env.MONGOLAB_URI or "mongodb://localhost/citycycledata"

Station = require "./model/Station"
StationStatus = require "./model/StationStatus"

app = express.createServer()

app.set 'view engine', 'coffeekup'
app.register '.coffeekup', require('coffeekup').adapters.express

io = require("socket.io").listen app

app.use express.static path.resolve __dirname, "..", "webroot"

app.get "/", (req, res) ->
	res.render "index"

app.get "/station/:station/day", (req, res) ->
	Station.findOne {number: req.params.station}, (err, station) ->
		return res.send 500 if err? or not station
		res.locals
			station: station
		res.render "day"

app.get "/station/:station/day.json", (req, res) ->
	async.waterfall [
		(cb) ->
			Station.findOne { number: req.params.station }, ["_id"], cb
		(station, cb) ->
			console.time "status"
			StationStatus
				.find({ station: station._id })
				.where("time")
					.gte(new Date().resetTime())
				.exec cb
	], (err, samples) ->
		console.timeEnd "status"
		return res.send 500 if err?

		json = {}
		json.available = []
		json.available.push [sample.time.getTime(), sample.available] for sample in samples

		json.free = []
		json.free.push [sample.time.getTime(), sample.free] for sample in samples

		res.send json

io.sockets.on "connection", (socket) ->
	socket.on "load", (msg) ->
		model = null

		if msg.name is "stations"
			model = Station

		Station.find {}, (err, stations) ->
			if msg.delta
				# msg.delta is a list of ids the client has. Figure out what 
				# they need / don't need.
				return socket.emit "data", 
					add: stations.filter (station) -> msg.delta.indexOf(station._id.toString()) is -1
					remove: msg.delta.filter (id) ->
							not stations.find (station) -> station._id.toString() is id
						.map (id) -> {id: id}

			socket.emit "data", all: stations
	
	socket.on "status", (msg) ->
		StationStatus
			.find({ station: msg.id })
			.where("time")
				.gte(new Date().resetTime())
			.exec (samples) ->
				data = []
				data.push [sample.time.getTime(), sample.available] for sample in samples
				console.log data
				socket.emit "statusdata", data


app.listen process.env.PORT or 1380

