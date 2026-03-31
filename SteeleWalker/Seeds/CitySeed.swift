import Foundation

enum CitySeed {

    struct Entry: Identifiable {
        let id: String       // "city_state" slug
        let city: String
        let state: String

        var displayName: String { "\(city), \(state)" }
    }

    // MARK: - Full list

    static let all: [Entry] = [
        // Alabama
        Entry(id: "birmingham_al", city: "Birmingham", state: "AL"),
        Entry(id: "huntsville_al", city: "Huntsville", state: "AL"),
        Entry(id: "mobile_al", city: "Mobile", state: "AL"),
        Entry(id: "montgomery_al", city: "Montgomery", state: "AL"),
        Entry(id: "tuscaloosa_al", city: "Tuscaloosa", state: "AL"),

        // Alaska
        Entry(id: "anchorage_ak", city: "Anchorage", state: "AK"),
        Entry(id: "fairbanks_ak", city: "Fairbanks", state: "AK"),
        Entry(id: "juneau_ak", city: "Juneau", state: "AK"),

        // Arizona
        Entry(id: "chandler_az", city: "Chandler", state: "AZ"),
        Entry(id: "gilbert_az", city: "Gilbert", state: "AZ"),
        Entry(id: "glendale_az", city: "Glendale", state: "AZ"),
        Entry(id: "mesa_az", city: "Mesa", state: "AZ"),
        Entry(id: "peoria_az", city: "Peoria", state: "AZ"),
        Entry(id: "phoenix_az", city: "Phoenix", state: "AZ"),
        Entry(id: "scottsdale_az", city: "Scottsdale", state: "AZ"),
        Entry(id: "surprise_az", city: "Surprise", state: "AZ"),
        Entry(id: "tempe_az", city: "Tempe", state: "AZ"),
        Entry(id: "tucson_az", city: "Tucson", state: "AZ"),

        // Arkansas
        Entry(id: "fayetteville_ar", city: "Fayetteville", state: "AR"),
        Entry(id: "fort_smith_ar", city: "Fort Smith", state: "AR"),
        Entry(id: "little_rock_ar", city: "Little Rock", state: "AR"),

        // California
        Entry(id: "anaheim_ca", city: "Anaheim", state: "CA"),
        Entry(id: "bakersfield_ca", city: "Bakersfield", state: "CA"),
        Entry(id: "berkeley_ca", city: "Berkeley", state: "CA"),
        Entry(id: "burbank_ca", city: "Burbank", state: "CA"),
        Entry(id: "chula_vista_ca", city: "Chula Vista", state: "CA"),
        Entry(id: "concord_ca", city: "Concord", state: "CA"),
        Entry(id: "corona_ca", city: "Corona", state: "CA"),
        Entry(id: "elk_grove_ca", city: "Elk Grove", state: "CA"),
        Entry(id: "escondido_ca", city: "Escondido", state: "CA"),
        Entry(id: "fontana_ca", city: "Fontana", state: "CA"),
        Entry(id: "fremont_ca", city: "Fremont", state: "CA"),
        Entry(id: "fresno_ca", city: "Fresno", state: "CA"),
        Entry(id: "fullerton_ca", city: "Fullerton", state: "CA"),
        Entry(id: "garden_grove_ca", city: "Garden Grove", state: "CA"),
        Entry(id: "glendale_ca", city: "Glendale", state: "CA"),
        Entry(id: "hayward_ca", city: "Hayward", state: "CA"),
        Entry(id: "huntington_beach_ca", city: "Huntington Beach", state: "CA"),
        Entry(id: "irvine_ca", city: "Irvine", state: "CA"),
        Entry(id: "lancaster_ca", city: "Lancaster", state: "CA"),
        Entry(id: "long_beach_ca", city: "Long Beach", state: "CA"),
        Entry(id: "los_angeles_ca", city: "Los Angeles", state: "CA"),
        Entry(id: "modesto_ca", city: "Modesto", state: "CA"),
        Entry(id: "moreno_valley_ca", city: "Moreno Valley", state: "CA"),
        Entry(id: "oakland_ca", city: "Oakland", state: "CA"),
        Entry(id: "oceanside_ca", city: "Oceanside", state: "CA"),
        Entry(id: "ontario_ca", city: "Ontario", state: "CA"),
        Entry(id: "oxnard_ca", city: "Oxnard", state: "CA"),
        Entry(id: "palmdale_ca", city: "Palmdale", state: "CA"),
        Entry(id: "pasadena_ca", city: "Pasadena", state: "CA"),
        Entry(id: "pomona_ca", city: "Pomona", state: "CA"),
        Entry(id: "rancho_cucamonga_ca", city: "Rancho Cucamonga", state: "CA"),
        Entry(id: "riverside_ca", city: "Riverside", state: "CA"),
        Entry(id: "roseville_ca", city: "Roseville", state: "CA"),
        Entry(id: "sacramento_ca", city: "Sacramento", state: "CA"),
        Entry(id: "salinas_ca", city: "Salinas", state: "CA"),
        Entry(id: "san_bernardino_ca", city: "San Bernardino", state: "CA"),
        Entry(id: "san_diego_ca", city: "San Diego", state: "CA"),
        Entry(id: "san_francisco_ca", city: "San Francisco", state: "CA"),
        Entry(id: "san_jose_ca", city: "San Jose", state: "CA"),
        Entry(id: "santa_ana_ca", city: "Santa Ana", state: "CA"),
        Entry(id: "santa_clarita_ca", city: "Santa Clarita", state: "CA"),
        Entry(id: "santa_rosa_ca", city: "Santa Rosa", state: "CA"),
        Entry(id: "stockton_ca", city: "Stockton", state: "CA"),
        Entry(id: "sunnyvale_ca", city: "Sunnyvale", state: "CA"),
        Entry(id: "thousand_oaks_ca", city: "Thousand Oaks", state: "CA"),
        Entry(id: "torrance_ca", city: "Torrance", state: "CA"),
        Entry(id: "vallejo_ca", city: "Vallejo", state: "CA"),
        Entry(id: "victorville_ca", city: "Victorville", state: "CA"),
        Entry(id: "visalia_ca", city: "Visalia", state: "CA"),

        // Colorado
        Entry(id: "arvada_co", city: "Arvada", state: "CO"),
        Entry(id: "aurora_co", city: "Aurora", state: "CO"),
        Entry(id: "boulder_co", city: "Boulder", state: "CO"),
        Entry(id: "colorado_springs_co", city: "Colorado Springs", state: "CO"),
        Entry(id: "denver_co", city: "Denver", state: "CO"),
        Entry(id: "fort_collins_co", city: "Fort Collins", state: "CO"),
        Entry(id: "lakewood_co", city: "Lakewood", state: "CO"),
        Entry(id: "pueblo_co", city: "Pueblo", state: "CO"),
        Entry(id: "thornton_co", city: "Thornton", state: "CO"),
        Entry(id: "westminster_co", city: "Westminster", state: "CO"),

        // Connecticut
        Entry(id: "bridgeport_ct", city: "Bridgeport", state: "CT"),
        Entry(id: "hartford_ct", city: "Hartford", state: "CT"),
        Entry(id: "new_haven_ct", city: "New Haven", state: "CT"),
        Entry(id: "stamford_ct", city: "Stamford", state: "CT"),
        Entry(id: "waterbury_ct", city: "Waterbury", state: "CT"),

        // Delaware
        Entry(id: "dover_de", city: "Dover", state: "DE"),
        Entry(id: "wilmington_de", city: "Wilmington", state: "DE"),

        // Florida
        Entry(id: "cape_coral_fl", city: "Cape Coral", state: "FL"),
        Entry(id: "clearwater_fl", city: "Clearwater", state: "FL"),
        Entry(id: "coral_springs_fl", city: "Coral Springs", state: "FL"),
        Entry(id: "fort_lauderdale_fl", city: "Fort Lauderdale", state: "FL"),
        Entry(id: "gainesville_fl", city: "Gainesville", state: "FL"),
        Entry(id: "hialeah_fl", city: "Hialeah", state: "FL"),
        Entry(id: "hollywood_fl", city: "Hollywood", state: "FL"),
        Entry(id: "jacksonville_fl", city: "Jacksonville", state: "FL"),
        Entry(id: "miami_fl", city: "Miami", state: "FL"),
        Entry(id: "miami_gardens_fl", city: "Miami Gardens", state: "FL"),
        Entry(id: "miramar_fl", city: "Miramar", state: "FL"),
        Entry(id: "orlando_fl", city: "Orlando", state: "FL"),
        Entry(id: "pembroke_pines_fl", city: "Pembroke Pines", state: "FL"),
        Entry(id: "pompano_beach_fl", city: "Pompano Beach", state: "FL"),
        Entry(id: "port_st_lucie_fl", city: "Port St. Lucie", state: "FL"),
        Entry(id: "st_petersburg_fl", city: "St. Petersburg", state: "FL"),
        Entry(id: "tallahassee_fl", city: "Tallahassee", state: "FL"),
        Entry(id: "tampa_fl", city: "Tampa", state: "FL"),
        Entry(id: "west_palm_beach_fl", city: "West Palm Beach", state: "FL"),

        // Georgia
        Entry(id: "athens_ga", city: "Athens", state: "GA"),
        Entry(id: "atlanta_ga", city: "Atlanta", state: "GA"),
        Entry(id: "augusta_ga", city: "Augusta", state: "GA"),
        Entry(id: "columbus_ga", city: "Columbus", state: "GA"),
        Entry(id: "savannah_ga", city: "Savannah", state: "GA"),

        // Hawaii
        Entry(id: "honolulu_hi", city: "Honolulu", state: "HI"),

        // Idaho
        Entry(id: "boise_id", city: "Boise", state: "ID"),
        Entry(id: "meridian_id", city: "Meridian", state: "ID"),
        Entry(id: "nampa_id", city: "Nampa", state: "ID"),

        // Illinois
        Entry(id: "aurora_il", city: "Aurora", state: "IL"),
        Entry(id: "chicago_il", city: "Chicago", state: "IL"),
        Entry(id: "elgin_il", city: "Elgin", state: "IL"),
        Entry(id: "joliet_il", city: "Joliet", state: "IL"),
        Entry(id: "naperville_il", city: "Naperville", state: "IL"),
        Entry(id: "peoria_il", city: "Peoria", state: "IL"),
        Entry(id: "rockford_il", city: "Rockford", state: "IL"),
        Entry(id: "springfield_il", city: "Springfield", state: "IL"),

        // Indiana
        Entry(id: "evansville_in", city: "Evansville", state: "IN"),
        Entry(id: "fort_wayne_in", city: "Fort Wayne", state: "IN"),
        Entry(id: "indianapolis_in", city: "Indianapolis", state: "IN"),
        Entry(id: "south_bend_in", city: "South Bend", state: "IN"),

        // Iowa
        Entry(id: "cedar_rapids_ia", city: "Cedar Rapids", state: "IA"),
        Entry(id: "des_moines_ia", city: "Des Moines", state: "IA"),

        // Kansas
        Entry(id: "kansas_city_ks", city: "Kansas City", state: "KS"),
        Entry(id: "olathe_ks", city: "Olathe", state: "KS"),
        Entry(id: "overland_park_ks", city: "Overland Park", state: "KS"),
        Entry(id: "topeka_ks", city: "Topeka", state: "KS"),
        Entry(id: "wichita_ks", city: "Wichita", state: "KS"),

        // Kentucky
        Entry(id: "lexington_ky", city: "Lexington", state: "KY"),
        Entry(id: "louisville_ky", city: "Louisville", state: "KY"),

        // Louisiana
        Entry(id: "baton_rouge_la", city: "Baton Rouge", state: "LA"),
        Entry(id: "new_orleans_la", city: "New Orleans", state: "LA"),
        Entry(id: "shreveport_la", city: "Shreveport", state: "LA"),

        // Maine
        Entry(id: "portland_me", city: "Portland", state: "ME"),

        // Maryland
        Entry(id: "baltimore_md", city: "Baltimore", state: "MD"),

        // Massachusetts
        Entry(id: "boston_ma", city: "Boston", state: "MA"),
        Entry(id: "cambridge_ma", city: "Cambridge", state: "MA"),
        Entry(id: "lowell_ma", city: "Lowell", state: "MA"),
        Entry(id: "springfield_ma", city: "Springfield", state: "MA"),
        Entry(id: "worcester_ma", city: "Worcester", state: "MA"),

        // Michigan
        Entry(id: "ann_arbor_mi", city: "Ann Arbor", state: "MI"),
        Entry(id: "detroit_mi", city: "Detroit", state: "MI"),
        Entry(id: "grand_rapids_mi", city: "Grand Rapids", state: "MI"),
        Entry(id: "lansing_mi", city: "Lansing", state: "MI"),
        Entry(id: "sterling_heights_mi", city: "Sterling Heights", state: "MI"),
        Entry(id: "warren_mi", city: "Warren", state: "MI"),

        // Minnesota
        Entry(id: "minneapolis_mn", city: "Minneapolis", state: "MN"),
        Entry(id: "rochester_mn", city: "Rochester", state: "MN"),
        Entry(id: "st_paul_mn", city: "St. Paul", state: "MN"),

        // Mississippi
        Entry(id: "jackson_ms", city: "Jackson", state: "MS"),

        // Missouri
        Entry(id: "columbia_mo", city: "Columbia", state: "MO"),
        Entry(id: "independence_mo", city: "Independence", state: "MO"),
        Entry(id: "kansas_city_mo", city: "Kansas City", state: "MO"),
        Entry(id: "springfield_mo", city: "Springfield", state: "MO"),
        Entry(id: "st_louis_mo", city: "St. Louis", state: "MO"),

        // Montana
        Entry(id: "billings_mt", city: "Billings", state: "MT"),
        Entry(id: "missoula_mt", city: "Missoula", state: "MT"),

        // Nebraska
        Entry(id: "lincoln_ne", city: "Lincoln", state: "NE"),
        Entry(id: "omaha_ne", city: "Omaha", state: "NE"),

        // Nevada
        Entry(id: "henderson_nv", city: "Henderson", state: "NV"),
        Entry(id: "las_vegas_nv", city: "Las Vegas", state: "NV"),
        Entry(id: "north_las_vegas_nv", city: "North Las Vegas", state: "NV"),
        Entry(id: "reno_nv", city: "Reno", state: "NV"),

        // New Hampshire
        Entry(id: "manchester_nh", city: "Manchester", state: "NH"),

        // New Jersey
        Entry(id: "elizabeth_nj", city: "Elizabeth", state: "NJ"),
        Entry(id: "jersey_city_nj", city: "Jersey City", state: "NJ"),
        Entry(id: "newark_nj", city: "Newark", state: "NJ"),
        Entry(id: "paterson_nj", city: "Paterson", state: "NJ"),

        // New Mexico
        Entry(id: "albuquerque_nm", city: "Albuquerque", state: "NM"),
        Entry(id: "las_cruces_nm", city: "Las Cruces", state: "NM"),
        Entry(id: "rio_rancho_nm", city: "Rio Rancho", state: "NM"),
        Entry(id: "santa_fe_nm", city: "Santa Fe", state: "NM"),

        // New York
        Entry(id: "buffalo_ny", city: "Buffalo", state: "NY"),
        Entry(id: "new_york_ny", city: "New York", state: "NY"),
        Entry(id: "rochester_ny", city: "Rochester", state: "NY"),
        Entry(id: "syracuse_ny", city: "Syracuse", state: "NY"),
        Entry(id: "yonkers_ny", city: "Yonkers", state: "NY"),

        // North Carolina
        Entry(id: "cary_nc", city: "Cary", state: "NC"),
        Entry(id: "charlotte_nc", city: "Charlotte", state: "NC"),
        Entry(id: "durham_nc", city: "Durham", state: "NC"),
        Entry(id: "fayetteville_nc", city: "Fayetteville", state: "NC"),
        Entry(id: "greensboro_nc", city: "Greensboro", state: "NC"),
        Entry(id: "raleigh_nc", city: "Raleigh", state: "NC"),
        Entry(id: "wilmington_nc", city: "Wilmington", state: "NC"),
        Entry(id: "winston_salem_nc", city: "Winston-Salem", state: "NC"),

        // North Dakota
        Entry(id: "fargo_nd", city: "Fargo", state: "ND"),

        // Ohio
        Entry(id: "akron_oh", city: "Akron", state: "OH"),
        Entry(id: "cincinnati_oh", city: "Cincinnati", state: "OH"),
        Entry(id: "cleveland_oh", city: "Cleveland", state: "OH"),
        Entry(id: "columbus_oh", city: "Columbus", state: "OH"),
        Entry(id: "dayton_oh", city: "Dayton", state: "OH"),
        Entry(id: "toledo_oh", city: "Toledo", state: "OH"),

        // Oklahoma
        Entry(id: "norman_ok", city: "Norman", state: "OK"),
        Entry(id: "oklahoma_city_ok", city: "Oklahoma City", state: "OK"),
        Entry(id: "tulsa_ok", city: "Tulsa", state: "OK"),

        // Oregon
        Entry(id: "eugene_or", city: "Eugene", state: "OR"),
        Entry(id: "portland_or", city: "Portland", state: "OR"),
        Entry(id: "salem_or", city: "Salem", state: "OR"),

        // Pennsylvania
        Entry(id: "allentown_pa", city: "Allentown", state: "PA"),
        Entry(id: "erie_pa", city: "Erie", state: "PA"),
        Entry(id: "philadelphia_pa", city: "Philadelphia", state: "PA"),
        Entry(id: "pittsburgh_pa", city: "Pittsburgh", state: "PA"),
        Entry(id: "reading_pa", city: "Reading", state: "PA"),

        // Rhode Island
        Entry(id: "providence_ri", city: "Providence", state: "RI"),

        // South Carolina
        Entry(id: "charleston_sc", city: "Charleston", state: "SC"),
        Entry(id: "columbia_sc", city: "Columbia", state: "SC"),
        Entry(id: "north_charleston_sc", city: "North Charleston", state: "SC"),

        // South Dakota
        Entry(id: "sioux_falls_sd", city: "Sioux Falls", state: "SD"),

        // Tennessee
        Entry(id: "chattanooga_tn", city: "Chattanooga", state: "TN"),
        Entry(id: "clarksville_tn", city: "Clarksville", state: "TN"),
        Entry(id: "knoxville_tn", city: "Knoxville", state: "TN"),
        Entry(id: "memphis_tn", city: "Memphis", state: "TN"),
        Entry(id: "murfreesboro_tn", city: "Murfreesboro", state: "TN"),
        Entry(id: "nashville_tn", city: "Nashville", state: "TN"),

        // Texas
        Entry(id: "amarillo_tx", city: "Amarillo", state: "TX"),
        Entry(id: "arlington_tx", city: "Arlington", state: "TX"),
        Entry(id: "austin_tx", city: "Austin", state: "TX"),
        Entry(id: "beaumont_tx", city: "Beaumont", state: "TX"),
        Entry(id: "brownsville_tx", city: "Brownsville", state: "TX"),
        Entry(id: "carrollton_tx", city: "Carrollton", state: "TX"),
        Entry(id: "corpus_christi_tx", city: "Corpus Christi", state: "TX"),
        Entry(id: "dallas_tx", city: "Dallas", state: "TX"),
        Entry(id: "denton_tx", city: "Denton", state: "TX"),
        Entry(id: "el_paso_tx", city: "El Paso", state: "TX"),
        Entry(id: "fort_worth_tx", city: "Fort Worth", state: "TX"),
        Entry(id: "frisco_tx", city: "Frisco", state: "TX"),
        Entry(id: "garland_tx", city: "Garland", state: "TX"),
        Entry(id: "grand_prairie_tx", city: "Grand Prairie", state: "TX"),
        Entry(id: "houston_tx", city: "Houston", state: "TX"),
        Entry(id: "irving_tx", city: "Irving", state: "TX"),
        Entry(id: "killeen_tx", city: "Killeen", state: "TX"),
        Entry(id: "laredo_tx", city: "Laredo", state: "TX"),
        Entry(id: "lubbock_tx", city: "Lubbock", state: "TX"),
        Entry(id: "mcallen_tx", city: "McAllen", state: "TX"),
        Entry(id: "mckinney_tx", city: "McKinney", state: "TX"),
        Entry(id: "mesquite_tx", city: "Mesquite", state: "TX"),
        Entry(id: "midland_tx", city: "Midland", state: "TX"),
        Entry(id: "pasadena_tx", city: "Pasadena", state: "TX"),
        Entry(id: "plano_tx", city: "Plano", state: "TX"),
        Entry(id: "round_rock_tx", city: "Round Rock", state: "TX"),
        Entry(id: "san_antonio_tx", city: "San Antonio", state: "TX"),
        Entry(id: "waco_tx", city: "Waco", state: "TX"),

        // Utah
        Entry(id: "provo_ut", city: "Provo", state: "UT"),
        Entry(id: "salt_lake_city_ut", city: "Salt Lake City", state: "UT"),
        Entry(id: "west_jordan_ut", city: "West Jordan", state: "UT"),
        Entry(id: "west_valley_city_ut", city: "West Valley City", state: "UT"),

        // Vermont
        Entry(id: "burlington_vt", city: "Burlington", state: "VT"),

        // Virginia
        Entry(id: "alexandria_va", city: "Alexandria", state: "VA"),
        Entry(id: "chesapeake_va", city: "Chesapeake", state: "VA"),
        Entry(id: "hampton_va", city: "Hampton", state: "VA"),
        Entry(id: "newport_news_va", city: "Newport News", state: "VA"),
        Entry(id: "norfolk_va", city: "Norfolk", state: "VA"),
        Entry(id: "richmond_va", city: "Richmond", state: "VA"),
        Entry(id: "virginia_beach_va", city: "Virginia Beach", state: "VA"),

        // Washington
        Entry(id: "bellevue_wa", city: "Bellevue", state: "WA"),
        Entry(id: "kent_wa", city: "Kent", state: "WA"),
        Entry(id: "seattle_wa", city: "Seattle", state: "WA"),
        Entry(id: "spokane_wa", city: "Spokane", state: "WA"),
        Entry(id: "tacoma_wa", city: "Tacoma", state: "WA"),
        Entry(id: "vancouver_wa", city: "Vancouver", state: "WA"),

        // West Virginia
        Entry(id: "charleston_wv", city: "Charleston", state: "WV"),

        // Wisconsin
        Entry(id: "green_bay_wi", city: "Green Bay", state: "WI"),
        Entry(id: "madison_wi", city: "Madison", state: "WI"),
        Entry(id: "milwaukee_wi", city: "Milwaukee", state: "WI"),

        // Wyoming
        Entry(id: "cheyenne_wy", city: "Cheyenne", state: "WY"),
    ]
}
