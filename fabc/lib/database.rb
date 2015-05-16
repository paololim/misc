require 'typed_class'

class Database < TypedClass

  field :user, String
  field :db_name, String

  def execute(query)
    command = "psql -U %s -c \"%s\" %s" % [user, query, db_name]
    puts command
    system(command) || raise("Command failed: %s" % command)
  end

  def select_all(query)
    data = []
    result = PostgresPR::Connection.new(db_name, user).query(query)
    fields = result.fields.map(&:name).map(&:to_sym)
    result.rows.each do |row|
      hash = {}
      row.each_with_index do |value, index|
        name = fields[index]
        if name.nil?
          raise "Missing name for index[%s] in query: %s" % [index, query]
        end
        hash[name] = value
      end
      data << hash
    end
    data
  end

  def select_one(query)
    rec = select_one_or_nil(query)
    if rec.nil?
      raise "Record not found for query: %s" % query
    end
    rec
  end

  def select_one_or_nil(query)
    select_all(query).first
  end

end
