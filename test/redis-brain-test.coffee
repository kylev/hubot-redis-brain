expect = require('chai').expect

describe 'redis-brain', ->
  it 'exports a function', ->
    expect(require('../src/redis-brain')).to.be.a('Function')
