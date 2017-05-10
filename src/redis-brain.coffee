# Description:
#   Persist hubot's brain to redis
#
# Configuration:
#   HUBOT_REDIS_BRAIN_URL - The redis connection URL passed to the driver. See the redis npm
#     module for documentation. Default: "redis://localhost:6379"
#   HUBOT_REDIS_BRAIN_PREFIX - The key prefix used when storing data in redis. Default: "hubot:"
#
# Commands:
#   None

Redis = require "redis"

warnOldEnv = (robot, env) ->
  oldKeys = ['REDISTOGO_URL', 'REDISCLOUD_URL', 'BOXEN_REDIS_URL', 'REDIS_URL']
  deprecatedUses = oldKeys.filter (o) -> env[o]

  if deprecatedUses.length > 0
    robot.logger.warning("Ignoring old environment variables %s; use HUBOT_REDIS_BRAIN_URL", deprecatedUses)

module.exports = (robot) ->
  warnOldEnv(robot, process.env)
  unless process.env.HUBOT_REDIS_BRAIN_URL
    robot.logger.info("HUBOT_REDIS_BRAIN_URL unset, using default")

  url = process.env.HUBOT_REDIS_BRAIN_URL || 'redis://localhost:6379'
  prefix =  process.env.HUBOT_REDIS_BRAIN_PREFIX || 'hubot:'
  client = Redis.createClient(url, no_ready_check: true, prefix: prefix)

  robot.brain.setAutoSave false

  getData = ->
    client.get "storage", (err, reply) ->
      if err
        throw err
      else if reply
        robot.logger.info "hubot-redis-brain: Data for #{prefix} brain retrieved from Redis"
        robot.brain.mergeData JSON.parse(reply.toString())
      else
        robot.logger.info "hubot-redis-brain: Initializing new data for #{prefix} brain"
        robot.brain.mergeData {}

      robot.brain.setAutoSave true

  client.on "error", (err) ->
    if /ECONNREFUSED/.test err.message

    else
      robot.logger.error err.stack

  client.on "connect", ->
    robot.logger.debug "hubot-redis-brain: Successfully connected to Redis"
    getData()

  robot.brain.on 'save', (data = {}) ->
    client.set "storage", JSON.stringify data

  robot.brain.on 'close', ->
    client.quit()
