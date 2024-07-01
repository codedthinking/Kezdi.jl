using Kezdi

df = CSV.read("~/Downloads/data/export_CAN_2023.csv", DataFrame)
names(df)

df = @keep df ISO_COUNTRY_CODE WIN_COUNTRY_CODE AWARD_VALUE_EURO

@with df begin
    @generate buyer_countries = split.(ISO_COUNTRY_CODE, "---")
    @generate seller_countries = split.(WIN_COUNTRY_CODE, "---")
    @generate n_buyers = length.(buyer_countries)
    @generate n_sellers = length.(seller_countries)
    @keep @if n_buyers == 1
    @generate buyer_country = first.(buyer_countries)
    @generate foreign_winner = !(buyer_country in seller_countries)
    @tabulate buyer_country foreign_winner
    @collapse n_tenders = rowcount(_n) sum_award = sum(AWARD_VALUE_EURO), by(buyer_country, foreign_winner)
    @regress log(sum_award) foreign_winner fe(buyer_country), cluster(buyer_country)
end