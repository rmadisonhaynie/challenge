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
  
  daysPrice = (fraction * car["price_per_day"]).round(0);
  price = (daysPrice + rental["distance"] * car["price_per_km"]);
  insurance = (price * 0.3 * 0.5).to_i;
  commission = {"insurance_fee"=> insurance, "assistance_fee"=> 100 * days, "drivy_fee"=> insurance - 100 * days};
  rentalsOut.push({"id" => rental["id"], "price" => price}, "commission" => commission);
end

output = {"rentals" => rentalsOut};
output.to_json;

outFile = File.new("output.json", "w");
JSON.dump(output, outFile);
outFile.close();