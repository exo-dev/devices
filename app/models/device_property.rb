class DeviceProperty
  include Mongoid::Document
  include Mongoid::Timestamps

  field :uri
  field :value
  field :pending, default: ""

  attr_accessible :uri, :value

  validates :uri, url: true

  embedded_in :device
end