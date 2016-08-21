require "json"
require "date"

# your code
dataFile = File.new("data.json", "r");
data = JSON.load(dataFile);
dataFile.close();

carMap = {};
for car in data["cars"]
  carMap[car["id"]] = {"price_per_day" => car["price_per_day"] , "price_per_km" => car["price_per_km"]};
end

rentalsOut = [];
for rental in data["rentals"]
  car = carMap[rental["car_id"]];
  days = (Date.parse(rental["end_date"]) - Date.parse(rental["start_date"])).to_i + 1;
  fraction = 0.5 * days + 0.1;
  if days < 1
    fraction += 0.4;
  elsif days < 4
    fraction += 0.4 * days;
  elsif days < 10
    fraction += 0.2 * (days + 4);
  elsif days >= 10
    fraction += 2.8;
  end
  
  daysPrice = fraction * car["price_per_day"];
  price = daysPrice + rental["distance"] * car["price_per_km"];
  rentalsOut.push({"id" => rental["id"], "price" => price.round(0)});
end

output = {"rentals" => rentalsOut};
output.to_json;

outFile = File.new("output.json", "w");
JSON.dump(output, outFile);
outFile.close();