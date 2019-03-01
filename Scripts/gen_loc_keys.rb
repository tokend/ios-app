source_file_path = "./TokenDWalletTemplate/Resources/Base.lproj/Localizable.strings"
target_file_path = "./TokenDWalletTemplate/Sources/LocKey.swift"

source_content = File.read(source_file_path)

source_content.encode!('UTF-16', :undef => :replace, :invalid => :replace, :replace => "")
source_content.encode!('UTF-8')

source_content_lines = source_content.lines

offset = "    "
loc_keys_string = "// This file is auto-generated\n\nimport Foundation\n\nenum LocKey: String {\n"
loc_keys_string += "// swiftlint:disable identifier_name\n"

source_content_lines.each do |line|
  
  keyValue = line.split("=")
  if keyValue.count < 2 
    next
  end
  
  keyPart = keyValue.first
  
  keyPart = keyPart.sub("\"", "").rstrip.chomp("\"")
  
  key = keyPart
  loc_keys_string += offset
  loc_keys_string += "case #{key}\n"

end

loc_keys_string += "}\n"
loc_keys_string += "// swiftlint:enable identifier_name\n"

loc_keys_string.gsub!(/\x00/, '')

target_file = File.open(target_file_path, "w")
target_file.write(loc_keys_string)
target_file.close
