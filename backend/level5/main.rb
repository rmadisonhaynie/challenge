require "json"
require "date"

# your code

#I assume all data in json was validated in frontend
class Rental
  COMMISSION_FRAC = 0.3;
  INSURANCE_COMM_FRAC = 0.5;
  ASSISTANCE_COST_PD = 100;
  DEDUCTIBLE_COST_PD = 400;
  
  #Discount after x days
  DISCOUNTS = [{"days"=>0, "discount"=>1},{"days"=>1, "discount"=>0.9},{"days"=>4, "discount"=>0.7},{"days"=>10, "discount"=>0.5}];
  
  def initialize(id, car, start_date, end_date, distance, deductible_reduction)
    @id = id;
    @car = car;
    @start_date = start_date;
    @end_date = end_date;
    @distance = distance;
    @deductible_reduction = deductible_reduction;
    @days = getDays();
    @price = price(car["price_per_day"], car["price_per_km"]);
    @driverAmount = - @price - getDeductibleAmount;
    @ownerAmount = (@price * (1 - COMMISSION_FRAC)).to_i;
    #instructions aren't clear who to favor insurance or assistance if assitance is more than insurance portion, i'll favor 
    #assistance. Then if assistance is more than commission I'll favor the owner. Very unlikely since it'd require very low
    #rental rates but just incase
    commission = (@price * COMMISSION_FRAC).to_i;
    @assistanceAmount = ASSISTANCE_COST_PD * @days;
    if commission < @assistanceAmount
      @assistanceAmount = commission;
      @insuranceAmount = 0;
    elsif (commission * INSURANCE_COMM_FRAC).to_i < @assistanceAmount
      @insuranceAmount = commission - @assistanceAmount;
    else
      @insuranceAmount = (commission * INSURANCE_COMM_FRAC).to_i;
    end
    @drivyAmount = commission - @insuranceAmount - @assistanceAmount + getDeductibleAmount;
  end
  
  def getDeductibleAmount
    if @deductible_reduction
      DEDUCTIBLE_COST_PD * @days;
    else
      0;
    end
  end
  
  def price(ppd, ppkm)
    size = DISCOUNTS.length;
    effectiveDays = 0;
    # DISCOUNTS should always be atleast size 1 with discount after zero days, but just in case
    if size == 0
      effectiveDays = @days;
    elsif size == 1;
      effectiveDays = @days * DISCOUNTS[0]["discount"];
    else
      #loop through each discount
      for i in 0..size-2
        #if days are less than next discount find difference in days and current discount days add to effective days and break
        #else add the difference between the next and current discount day difference with the rate
        if @days <= DISCOUNTS[i + 1]["days"]
          effectiveDays += (@days - DISCOUNTS[i]["days"]) * DISCOUNTS[i]["discount"];
          break;
        else
          effectiveDays += (DISCOUNTS[i + 1]["days"] - DISCOUNTS[i]["days"]) * DISCOUNTS[i]["discount"]
          if i == size - 2
            effectiveDays += (@days - DISCOUNTS[i + 1]["days"]) * DISCOUNTS[i + 1]["discount"];
          end
        end
      end
    end
    daysPrice = (effectiveDays * ppd).round(0);
    (daysPrice + @distance * ppkm);
  end
  
  def getDays
    (Date.parse(@end_date) - Date.parse(@start_date)).to_i + 1;
  end
  
  def getActionType(amount)
    if amount < 0
      "debit";
    else
      "credit";
    end
  end
  
  def getActions
    actions = [
        {
          "who"=> "driver",
          "type"=> getActionType(@driverAmount),
          "amount"=> @driverAmount.abs
        },
        {
          "who"=> "owner",
          "type"=> getActionType(@ownerAmount),
          "amount"=> @ownerAmount.abs
        },
        {
          "who"=> "insurance",
          "type"=> getActionType(@insuranceAmount),
          "amount"=> @insuranceAmount.abs
        },
        {
          "who"=> "assistance",
          "type"=> getActionType(@assistanceAmount),
          "amount"=> @assistanceAmount.abs
        },
        {
          "who"=> "drivy",
          "type"=> getActionType(@drivyAmount),
          "amount"=> @drivyAmount.abs
        }
      ];
  end
  
  def getId
    @id;
  end
end

dataFile = File.new("data.json", "r");
data = JSON.load(dataFile);
dataFile.close();

#Making car data a map with id as key
carMap = {};
for car in data["cars"]
  carMap[car["id"]] = {"price_per_day" => car["price_per_day"] , "price_per_km" => car["price_per_km"]};
end

rentalsOut = [];
for rental in data["rentals"]
  r = Rental.new(rental["id"], carMap[rental["car_id"]], rental["start_date"], rental["end_date"], rental["distance"], rental["deductible_reduction"]);
  rentalOut = {"id" => r.getId, "actions"=> r.getActions};
  rentalsOut.push(rentalOut);
end

output = {"rentals" => rentalsOut};
output.to_json;

outFile = File.new("output.json", "w");
JSON.dump(output, outFile);
outFile.close();