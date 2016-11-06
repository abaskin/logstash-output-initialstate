# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"
require "initialstate"

# Output data to Initial State.
class LogStash::Outputs::InitialState < LogStash::Outputs::Base
  config_name "initialstate"

  # Supply the Intial State bucket key.
  #
  # Example:
  # [source,ruby]
  #     filter {
  #       initialstate {
  #         bucket_key => "zxse345s"
  #       }
  #     }
  config :bucket_key, :validate => :string, :required => true

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

  # The hash used to specify key / value pairs.
  # Note the use of sprintf format to get the values of fields.
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
  config :timestamp, :validate => :string, :default => "@timestamp"

  public
  def register
  end # def register

  public
  def receive(event)
    begin
      @epoch = event.get(@epoch) unless (@epoch).nil?
      out_data = Array.new
      @source.each do |stream_key,stream_value|
        event_data = Event.new stream_key, stream_value, epoch=@epoch, iso8601=event.get(@timestamp)
        out_data << event_data.to_hash
      end
      bucket = Bucket.new @bucket_key, @access_key
      bucket.dump out_data
    rescue Exception => e
      @logger.warn("Inital State threw exception", :exception => e.message, :backtrace => e.backtrace, :class => e.class.name)
    end
  end # def event
end # class LogStash::Outputs::InitialState
