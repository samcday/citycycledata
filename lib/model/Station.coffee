mongoose = require "mongoose"
Schema = mongoose.Schema

Station = new Schema
	name: String
	number:
		type: String
		index:
			unique: true
	address: String
	fullAddress: String
	lat: String
	long: String
	open: Boolean
	bonus: Boolean
	modified: Date
	created:
		type: Date
		default: () ->
			new Date()

Station.pre "save", (next) ->
	@modified = new Date()
	next()

module.exports = mongoose.model "Station", Station