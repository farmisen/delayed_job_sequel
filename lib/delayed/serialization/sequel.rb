class ::Sequel::Model
  yaml_as "tag:ruby.yaml.org,2002:Sequel"

  def self.yaml_new(klass, tag, val)
    obj = klass[val['values'][:id]]
    raise DeserializationError if obj.nil?
    obj
  end

  def to_yaml_properties
    ['@values']
  end
end

