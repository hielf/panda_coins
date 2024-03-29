dir = Rails.root.to_s + "/tmp/csv/"
dump_file = dir + "/" + "dump_sql.sql"

postgres = PG.connect :host => 'postgres.ripple-tech.com', :port => '5432', :dbname => 'panda_quant', :user => 'chesp', :password => ''

sql = "select max(date) as date from hsi_fut;"
res = postgres.exec(sql)
begin_date = res.first["date"].to_date.strftime('%Y%m%d')

Dir.entries(dir).sort.each do |d|
  next if d == '.' or d == '..'
  path = dir + d
  next if File.file?(path)
  next if begin_date && d.to_i < begin_date.to_i
  csv_file = Dir.glob(File.join(path, '*.*')).max { |a,b| File.ctime(a) <=> File.ctime(b) }
  # Dir.entries(path).sort.each do |file|
  #   next if file == '.' or file == '..'
  #   file_path = path + "/" + file
  #   File.file?(file_path)
  #   p file_path
  # end
  p csv_file
  csv_text = File.read(csv_file)
  csv = CSV.parse(csv_text, :headers => true)
  count = 0
  csv.each do |row|
    # Moulding.create!(row.to_hash)
    h = row.to_hash
    sql = "insert into hsi_fut_tmp (select 0 as index, '#{h["date"]}' as date, #{h["open"]} as open,#{h["high"]} as high,#{h["low"]} as low,#{h["close"]} as close,#{h["volume"]} as volume,#{h["barCount"]} as barCount,#{h["average"]} as average);"
    postgres.exec(sql)
    count = count + 1
    p count
  end
  sql = "insert into hsi_fut select * from hsi_fut_tmp b where not exists (select 1 from hsi_fut a where a.date = b.date);"
  postgres.exec(sql)
  sql = "truncate table hsi_fut_tmp;"
  postgres.exec(sql)
  sleep 0.2
end
