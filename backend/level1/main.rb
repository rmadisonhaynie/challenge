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
  price = days * car["price_per_day"] + rental["distance"] * car["price_per_km"];
  rentalsOut.push({"id" => rental["id"], "price" => price});
end

output = {"rentals" => rentalsOut};
output.to_json;

outFile = File.new("output.json", "w");
JSON.dump(output, outFile);
outFile.close();