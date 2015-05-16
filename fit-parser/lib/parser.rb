class Parser

  def initialize
  end

  def Parser.parse(file)
    headers = nil
    FasterCSV.foreach(file) do |row_array|
      if headers.nil?
        headers = row_array
      else
        row = {}
        headers.each_with_index do |field, index|
          value = row_array[index]
          if value.to_s.strip != ""
            row[field] = value
          end
        end
        puts row.inspect
      end
    end
    nil
  end

end
