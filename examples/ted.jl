using Kezdi

df = CSV.read("~/Downloads/data/export_CAN_2023.csv", DataFrame)
names(df)

df = @keep ISO_COUNTRY_CODE WIN_COUNTRY_CODE AWARD_VALUE_EURO

function distance(country1, country2)
    country1 == country2 ? 0.0 : 1.0
end

pair(x1, x2) = (x1, x2)

@with df begin
    @generate buyer_countries = split.(ISO_COUNTRY_CODE, "---")
    @generate seller_countries = split.(WIN_COUNTRY_CODE, "---")
    @generate n_buyers = length.(buyer_countries)
    @generate n_sellers = length.(seller_countries)
    @keep @if n_buyers == 1
    @generate buyer_country = first.(buyer_countries)
    @generate foreign_winner = !(buyer_country in seller_countries)
    @tabulate buyer_country foreign_winner
    intermediate = @generate distance = distance.(buyer_country, seller_countries)
    @generate mean_distance = mean.(distance.(buyer_country, seller_countries))
    @collapse n_tenders = rowcount(_n) sum_award = sum(AWARD_VALUE_EURO) mean_distance = mean(mean_distance), by(buyer_country, foreign_winner)
    @regress log(sum_award) log(n_tenders) foreign_winner fe(buyer_country), cluster(buyer_country)
end