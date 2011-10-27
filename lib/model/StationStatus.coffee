mongoose = require "mongoose"
Schema = mongoose.Schema

StationStatus = new Schema
	station:
		type: Schema.ObjectId
		ref: "Station"
	available: Number
	free: Number
	total: Number
	ticket: Boolean
	time:
		type: Date
		default: () ->
			new Date()

module.exports = mongoose.model "StationStatus", StationStatus