# encoding: utf-8
require 'logstash/outputs/base'
require 'logstash/namespace'
require 'httparty'
require 'openssl'
require 'json'

module Initial_State

  module Default
    BASE_URI = 'https://groker.initialstate.com/api'.freeze
  end

  module Error
    class NoAccessKeyError < StandardError
      def initialize(msg='You must specify an access key')
        super
      end
    end

    class NoBucketKeyError < StandardError
      def initialize(msg='You must specify a bucket key and/or bucket name')
        super
      end
    end

    class RequestError < StandardError; end
  end

  class Bucket
    include HTTParty
    EVENT_ENDPOINT = '/events'
    BUCKET_ENDPOINT = '/buckets'
    EVENT_URI = Initial_State::Default::BASE_URI + EVENT_ENDPOINT
    BUCKET_URI = Initial_State::Default::BASE_URI + BUCKET_ENDPOINT

    attr_reader :bucket_name, :bucket_key, :access_key

    def initialize(bucket_name, bucket_key, access_key)
      @bucket_name = bucket_name
      @bucket_key = bucket_key
      @access_key = access_key
      raise Initial_State::Error::NoBucketKeyError if @bucket_name.nil? && @bucket_key.nil?
      raise Initial_State::Error::NoAccessKeyError if @access_key.nil?
      @bucket_key = OpenSSL::Digest::SHA512.hexdigest @bucket_name if @bucket_key.nil?
      dump ({'bucketKey' => @bucket_key, 'bucketName' => @bucket_name}), BUCKET_URI
    end

    def dump(event,uri = EVENT_URI)
      post uri, prepare(event)
    end

    private

    def prepare(event)
      {
        body: event.respond_to?(:to_hash) ? event.to_hash.to_json : event.to_json,
        headers: {
          'X-IS-AccessKey' => access_key,
          'X-IS-BucketKey' => bucket_key,
          'Content-Type' => 'application/json',
          'Accept-Version' => '0.0.1'
        }
      }
    end

    def post(uri, data)
      res = HTTParty.post(uri, data)
      raise Initial_State::Error::RequestError, res.message if res.code/100 != 2
      res.body
    end
  end

  class Event
    attr_reader :key, :value, :epoch, :iso

    def initialize(key, value, epoch=nil, iso=nil)
      @key = key
      @value = value
      @epoch = epoch
      @iso = iso
    end

    def push(bucket_key, access_key=nil)
      bucket = Bucket.new bucket_key, access_key
      bucket.dump self
    end

    def to_hash
      data = {
        key: key,
        value: value
      }
      data[:epoch] = epoch unless epoch.nil?
      data[:iso] = iso unless iso.nil?
      data
    end
  end
end

# Output data to Initial State.
class LogStash::Outputs::InitialState < LogStash::Outputs::Base
  config_name 'initialstate'

  # Supply the Intial State bucket name, supports sprintf format. A new bucket and
  # bucket key will be created if required. You must specify a bucket name and/or
  # a bucket key.
  #
  # Example:
  # [source,ruby]
  #     filter {
  #       initialstate {
  #         bucket_name => "CPU Temp %{server_name}"
  #       }
  #     }
  config :bucket_name, :validate => :string, :default => nil

  # Supply the Intial State bucket key. If not specifed a SHA512 hash on the
  # bucket name will be used.
  #
  # Example:
  # [source,ruby]
  #     filter {
  #       initialstate {
  #         bucket_key => "b070838"
  #       }
  #     }
  config :bucket_key, :validate => :string, :default => nil

  # Supply the Intial State access key.
  #
  # Example:
  # [source,ruby]
  #     filter {
  #       initialstate {
  #         access_key => "fakee8do2JQN3Eos8Ah2FS8uiFD3Ola2"
  #       }
  #     }
  config :access_key, :validate => :string, :required => true

  # The hash used to specify key / value pairs. Note the use of sprintf
  # format to specify the value of fields
  # Example:
  # [source,ruby]
  #     filter {
  #       initialstate {
  #         source => [ "%{target_name}" => "%{rtt}",
  #                     "city" => "%{city_name}" ]
  #       }
  #     }
  config :source, :validate => :hash, :required => true

  # The field containing the epoch to be output to Initial State.
  # Epoch is in seconds with fractional seconds to right of decimal.
  #
  # Example:
  # [source,ruby]
  #     filter {
  #       initialstate {
  #         epoch => "epoch"
  #       }
  #     }
  config :epoch, :validate => :string, :default => nil

  # The field containing the ISO-8601 timestamp to be output to Initial State.
  #
  # Example:
  # [source,ruby]
  #     filter {
  #       initialstate {
  #         timestamp => "@timestamp"
  #       }
  #     }
  config :timestamp, :validate => :string, :default => '@timestamp'

  public
  def register
  end # def register

  public
  def receive(event)
    begin
      @epoch = event.get(@epoch) unless (@epoch).nil?
      event_data = Array.new
      @source.each do |stream_key,stream_value|
        istate_event = Initial_State::Event.new event.sprintf(stream_key), event.sprintf(stream_value), @epoch, event.get(@timestamp)
        event_data << istate_event.to_hash
      end
      bucket = Initial_State::Bucket.new event.sprintf(@bucket_name), @bucket_key, @access_key
      bucket.dump event_data
    rescue Exception => e
      @logger.warn('Inital State threw exception', :exception => e.message, :backtrace => e.backtrace, :class => e.class.name)
    end
  end # def event
end # class LogStash::Outputs::InitialState
