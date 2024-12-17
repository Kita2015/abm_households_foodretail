;; version 2.9 ;;

extensions [ rnd table ]


;;;;;;;;;;;;;;;;;;;;;
;; state variables ;;
;;;;;;;;;;;;;;;;;;;;;

breed [ persons person ]
breed  [ households household ]
breed  [ food-outlets food-outlet ]
breed [ foods food ]

;directed-link-breed [ parents parent ]
undirected-link-breed [friendships friendship ] ;assumption: friendships are mutual experiences
undirected-link-breed [family-memberships family-membership]
directed-link-breed [household-memberships household-membership]


globals [
  diet-list ;weighted list of diets
  diets-list ;list with only diets
  product-list ; weighted list of products
  income-levels
  id-households
  cooked-meat
  cooked-fish
  cooked-vegetarian
  cooked-vegan
  report-sales-table
  report-stock-table
  report-saved-stock-table
  report-delta-stock-table
  report-median-sales-table
  report-median-stock-table
  income-levels-list
  income-level-price-table
  report-meals-cooked-table
  report-saved-meals-cooked-table
  report-delta-meals-cooked-table
  report-diet-prefs-table
  report-saved-diet-prefs-table
  report-delta-diet-prefs-table
  business-duration-list
  low-income-affordability-table
  middle-income-affordability-table
  high-income-affordability-table
  diets-affordability-table
  meal-quality-variance

]


persons-own [
  ;age
  diet
  is-cook?
  cooking-skills
  cooks-cooking-skills
  h-id
  dinner-friends
  dinner-members
  shopping-list
  meal-to-cook
  my-last-dinner
  last-meals-quality
  last-meal-enjoyment
  meal-enjoyments-table
  my-cook
  my-dinner-guests
  network-diet-diversity
  ;egoism
  status
  neophobia
  individualism
  at-home?
  my-supermarket
  sorted-food-outlets
  bought?
  supermarket-changes

]

households-own [
  income-level
  id ; identifier
  members
  meal-cooked?
  empty-house?
  diet-diversity
  vip-preference
]

food-outlets-own [
  potential-costumers
  nr-protein-sources
  product-selection
  sales-table
  sales
  initial-stock-table
  stock-table
  no-sales-count
  business-orientation ;0 = not considering sustainability at all, 2 = considering sustainability in assortment a lot
  opening-day
  stock-check-list
]

foods-own [
  protein-type
  serves-diet
  ;price
  ;availability
]

;;;;;;;;;;;
;; SETUP ;;
;;;;;;;;;;;

to setup
  clear-all
  set error? false
  setup-seed
  setup-globals
  setup-households
  setup-persons
  setup-families
  show-families
  setup-friendships
  visualization
  setup-food-outlets
  ;setup-foods
  reset-ticks
end

to setup-seed
  if not fixed-seed?  [
    set current-seed new-seed
  ]
  random-seed current-seed
end

to setup-globals

  set diet-list (list (list "meat" 0.94 ) (list  "fish" 0.02 ) (list "vegetarian" 0.02 ) (list "vegan" 0.02 )) ;hard-coded values of dietary identities in the Netherlands
  set diets-list (list "meat" "fish" "vegetarian" "vegan")
  set income-levels (list (list "low" 0.5) (list "middle" 0.4) (list "high" 0.1)) ;hard-coded distribution of income levels in the Netherlands
  set income-levels-list (list "low" "middle" "high")
  set product-list (list (list "meat" 0.7) (list "fish" 0.6) (list "vegetarian" 0.5) (list "vegan" 0.1) ) ;hard-coded random values, should be based on real data
  set id-households 0
  set cooked-meat 0
  set cooked-fish 0
  set cooked-vegetarian 0
  set cooked-vegan 0
  set report-sales-table table:make
  set report-stock-table table:make
  set report-median-sales-table table:make
  set report-median-stock-table table:make
  set report-meals-cooked-table table:make
  set report-saved-meals-cooked-table table:make
  set report-delta-meals-cooked-table table:make
  set report-diet-prefs-table table:make
  set report-saved-diet-prefs-table table:make
  set report-delta-diet-prefs-table table:make
  set report-saved-stock-table table:make
  set report-delta-stock-table table:make
  set business-duration-list []
  set low-income-affordability-table table:make
  set middle-income-affordability-table table:make
  set high-income-affordability-table table:make
  set diets-affordability-table table:make
  set meal-quality-variance 0.1 ;hard-coded 10% standard deviation of a cook's cooking skills

  foreach diets-list [ diets ->
    table:put report-sales-table diets 0
    table:put report-stock-table diets 0
    table:put report-median-sales-table diets 0
    table:put report-median-stock-table diets 0
    table:put report-meals-cooked-table diets 0
    table:put report-saved-meals-cooked-table diets 0
    table:put report-delta-meals-cooked-table diets 0
    table:put report-saved-diet-prefs-table diets 0
    table:put report-delta-diet-prefs-table diets 0
    table:put report-saved-stock-table diets 0
    table:put report-delta-stock-table diets 0
  ]

  table:put diets-affordability-table "meat" 10
  table:put diets-affordability-table "fish" 2
  table:put diets-affordability-table "vegetarian" 3
  table:put diets-affordability-table "vegan" 2


end

to setup-households
  create-households initial-nr-households
  ask households [
    move-to one-of patches ;with [not any? households-here]
    set shape "house"
    set color 37
    set id id-households + 1
    set id-households id-households + 1 ;each households updates the global variable id-households
                                        ;create household with members
    set income-level first rnd:weighted-one-of-list income-levels [ [p] -> last p ]

    table:put low-income-affordability-table "meat" 7.5
    table:put low-income-affordability-table "fish" 1
    table:put low-income-affordability-table "vegetarian" 0.5
    table:put low-income-affordability-table "vegan" 0.1

    table:put middle-income-affordability-table "meat" 5
    table:put middle-income-affordability-table "fish" 1
    table:put middle-income-affordability-table "vegetarian" 1.5
    table:put middle-income-affordability-table "vegan" 1

    table:put high-income-affordability-table "meat" 2.5
    table:put high-income-affordability-table "fish" 1
    table:put high-income-affordability-table "vegetarian" 2.5
    table:put high-income-affordability-table "vegan" 2

    let new-family random-normal mean-family-size sd-family-size
    let new-family-abs abs new-family
    hatch-persons new-family-abs + 1
    set empty-house? false
    set meal-cooked? false
    set diet-diversity 0
    set vip-preference "none"

  ]

  ;check: no more than one house per patch
  ;  ask patches with [count households-here > 1] [
  ;    error "more than one house here!"
  ;  ]
end

to setup-persons
  ask persons [
    ;set age random-normal 41 25 ; mean and sd are chosen based on Dutch demographic data
    set shape "person"
    set color pink
    set diet first rnd:weighted-one-of-list diet-list [ [p] -> last p ]
    set is-cook? false
    set shopping-list []
    set meal-to-cook "none"
    set cooking-skills random-float 1
    set status random-float 1
    set neophobia random-float 1
    set individualism random-float 1
    set my-last-dinner "none"
    set last-meals-quality "none"
    set last-meal-enjoyment "none"
    set meal-enjoyments-table table:make

    foreach diets-list [ diets ->
      table:put meal-enjoyments-table diets 0
    ]

    set network-diet-diversity 0
    set cooks-cooking-skills 0
    set my-cook "nobody"
    set my-dinner-guests "nobody"
    set my-supermarket "none"
    set bought? false
  ]

  foreach diets-list [ diets ->
    table:put report-diet-prefs-table diets 0
    let nr-diets count persons with [diet = diets]
    table:put report-diet-prefs-table diets nr-diets
  ]

end

to setup-families
  ask households [
    set members persons-here  ; households set up a family with the persons on his patch

  ]

  ask persons [
    ;create family with household members
    set h-id first [id] of households-here ; persons set h-id based on id of household
    set at-home? true
    let my-family other persons-here ; persons set up a family with the persons in the same household
    create-family-memberships-with my-family [set color pink] ; persons create family bonds
    let my-house households with [id = [h-id] of myself]
    create-household-membership-from one-of my-house [set color 37]
    set dinner-members family-membership-neighbors
  ]

end

to show-families
  ask persons [
    left random 360
    forward 1
  ]
end

to setup-friendships
  ifelse friendships? = true [
    print ("")
    ask persons [
      let potential-friends other persons with [h-id != [h-id] of myself]
      let nr-friendships random nr-friends
      repeat nr-friendships [create-friendship-with one-of potential-friends [set color 9.9]]
      set dinner-friends friendship-neighbors ;this should be an agentset
      set label count dinner-friends
    ]
  ]
  ;friendships? = false
  [
    ask persons [
      set dinner-friends turtle-set self
    ]
  ]


  ask friendships [set hidden? true]
end


to setup-food-outlets
  create-food-outlets initial-nr-food-outlets
  ask food-outlets [
    move-to one-of patches with [not any? turtles-here]
    set shape "square 2"
    set color 25
    set business-orientation random-float 2
    set opening-day 0
    set stock-check-list []
    ;food-outlet counts number of persons in certain radius
    set potential-costumers count persons in-radius food-outlet-service-area

    ;set size based on fraction of population served
    let nr-products "none"
    let my-fraction ( potential-costumers / count persons )

    ;based on quantiles of fraction of population served, the food outlet will set his size
    (ifelse my-fraction <= 0.25 [
      set size 1
      set nr-products 1
      ]
      my-fraction > 0.25 and my-fraction <= 0.5 [
        set size 2
        set nr-products 2
      ]
      my-fraction > 0.25 and my-fraction <= 0.75 [
        set size 3
        set nr-products 3
      ]
      my-fraction > 0.75 [
        set size 4
        set nr-products 4
      ]
      ;if calculation of population-fraction did not go right
      [print (list who "I cannot calculate my size and how many products I will offer to my costumers")]
    )

    set nr-protein-sources nr-products
    set product-selection map first rnd:weighted-n-of-list nr-products product-list [ [p] -> last p ] ;based on a weighted list, food outlets choose the products for their shelves
                                                                                                      ;show product-selection


    ;food outlets determine for each product in their product-selection, how much of this product is in stock

    set initial-stock-table table:make
    set sales-table table:make
    set stock-table table:make


      foreach diets-list [ diets ->
        table:put initial-stock-table diets ifelse-value (member? diets product-selection) [
          round ( (potential-costumers / nr-products) )
        ] [
          0
        ]

        ;show (word "My initial stock of " diets " is " (table:get initial-stock-table diets))
        table:put sales-table diets 0
        table:put stock-table diets table:get initial-stock-table diets
        ;show stock-table
      ]

      (ifelse more-sustainable-shops? = true or less-animal-proteins? = true [

      foreach diets-list [ diets ->
        table:put initial-stock-table diets ifelse-value (member? diets product-selection) [
          round ( (potential-costumers / nr-products))
        ] [
          0
        ]

        ;show (word "My initial stock of " diets " is " (table:get initial-stock-table diets))
        table:put sales-table diets 0
        table:put stock-table diets table:get initial-stock-table diets

      ]

      set product-selection diets-list

      ]

      more-sustainable-shops? = false or less-animal-proteins? = false [
        ;do nothing
      ]

      ;if something goes wrong
      [show "I cannot decide if I will become more sustainable or have less animal proteins over time or not!"]
    )

    set no-sales-count 0
    set label (list potential-costumers product-selection)

  ]


  ask persons [
    set sorted-food-outlets sort-on [distance myself] food-outlets
    set supermarket-changes length sorted-food-outlets
  ]

end


;;;;;;;;;
;; RUN ;;
;;;;;;;;;

to go

  if ticks = 365 * 10 or error? = true [stop]

  closure-of-tick

  ;interventions
  influence-diets
  more-sustainable-shops
  less-animal-proteins-shops

  ;start having dinner
  select-group-and-cook

  ;ask cooks
  select-meal

  ;ask persons

  set-meal-evaluation
  update-diet-preference
  evaluate-meal

  ;ask food outlets
  check-sales
  update-stock

  ;interface visuals
  visualization

  ;reporters
  prepare-sales-reporter
  prepare-stock-reporter
  prepare-relative-change-meals-cooked-reporter
  prepare-relative-change-dietary-preferences-reporter
  prepare-relative-change-stocks-reporter


  tick

end

to closure-of-tick

  ask persons with [at-home? = false] [
    let my-home one-of households with [id = [h-id] of myself]
    move-to my-home
    set at-home? true
    left random 360
    forward 1
  ]

  ask persons [
    set shopping-list []
    set meal-to-cook "none"
    set is-cook? false
    set my-dinner-guests "nobody"
    set my-cook "nobody"
    set cooks-cooking-skills "none"
    set last-meals-quality "none"
    set last-meal-enjoyment "none"
    set bought? false

    let network-members (turtle-set self dinner-friends dinner-members) ;
    let diets-network [ (list diet) ] of network-members
    let unique-diets-network remove-duplicates diets-network
    let count-diets-network length(unique-diets-network)
    set network-diet-diversity count-diets-network
  ]

  ask persons [
    set sorted-food-outlets sort-on [distance myself] food-outlets
  ]

  ask households [
    set meal-cooked? false
    set empty-house? false
    let diets-members [ (list diet) ] of members
    let unique-diets remove-duplicates diets-members
    let count-diets length(unique-diets)
    set diet-diversity count-diets
  ]

  ask food-outlets [
    set stock-check-list []
    foreach diets-list [ diets ->
      table:put sales-table diets 0
    ]
  ]

  foreach diets-list [diets ->
    table:put report-delta-meals-cooked-table diets 0
    table:put report-delta-diet-prefs-table diets 0
    table:put report-delta-stock-table diets 0
  ]

end

to influence-diets

  if influencers? = true [

    if ticks = 365 [


      (ifelse diet-influencers = "none" [
        ;do nothing
        ]

        diet-influencers = "random" [

          let count-persons count persons
          let nr-influencers p-influencers * count-persons
          let influencers n-of nr-influencers persons


          ask influencers [set diet influencers-diet]

          set diet-influencers "none"

        ]

        diet-influencers = "low-status" [

          let low-status-persons persons with [status <= 0.25]

          let count-low-status-persons count low-status-persons
          let nr-influencers p-influencers * count-low-status-persons
          let influencers n-of nr-influencers low-status-persons


          ask influencers [set diet influencers-diet]

          set diet-influencers "none"
        ]



        diet-influencers = "high-status" [
          let high-status-persons persons with [status >= 0.75]
          let count-high-status-persons count high-status-persons
          let nr-influencers p-influencers * count-high-status-persons
          let influencers n-of nr-influencers high-status-persons

          ask influencers [set diet influencers-diet]

          set diet-influencers "none"
        ]

        ;if something goes wrong
        [print "The model was not able to use influencers to change dietary preference of part of the population"]
      )
    ]

  ]



end

to more-sustainable-shops

  if more-sustainable-shops? = true [

    let year-passed ticks mod 365
    let update-shops "none"

    ifelse year-passed = 1 [
      set update-shops true
    ]
    ;if year-passed != 1
    [set update-shops false]

    if update-shops = true [

      let sustainable-foods []


      ;if a food outlet already sells vegetarian and vegan

      ;check product selection of food outlet
      ask food-outlets [

        set sustainable-foods (list "vegetarian" "vegan")
        ;show (list "tick" ticks initial-stock-table)
        ;update sustainable stocks
        foreach sustainable-foods [ food-item ->

          let current-stock table:get initial-stock-table food-item

          (ifelse current-stock != 0 [

            let assortment-change (p-more-sustainable * business-orientation * current-stock)
            show assortment-change
            let new-stock current-stock + assortment-change
            table:put initial-stock-table food-item round new-stock
            table:put stock-table food-item table:get initial-stock-table food-item
            ]

            current-stock = 0 [ ;if the food outlet did not sell vegetarian and vegan before, it will now start selling some products
              let assortment-change (business-orientation * potential-costumers * p-more-sustainable)
              table:put initial-stock-table food-item round assortment-change
              table:put stock-table food-item table:get initial-stock-table food-item
            ]

            ;if something goes wrong
            [show "I was not able to check if I already sold vegetarian or vegan products!"]
          )

          ;show (list "tick" ticks initial-stock-table)


        ]
      ]

    ]
  ]



end

to less-animal-proteins-shops

  if less-animal-proteins? = true [

    let year-passed ticks mod 365
    let update-shops "none"

    ifelse year-passed = 1 [
      set update-shops true
    ]
    ;if year-passed != 1
    [set update-shops false]

    if update-shops = true [

      let animal-foods []

      ;if a food outlet already sells meat and fish

      ;check product selection of food outlet
      ask food-outlets [

        set animal-foods (list "meat" "fish")
        ;show (list "tick" ticks initial-stock-table)
        ;update sustainable stocks
        foreach animal-foods [ food-item ->

          let current-stock table:get initial-stock-table food-item

          (ifelse current-stock != 0 [

            let assortment-change (p-less-animal-proteins * business-orientation * current-stock)
            let new-stock current-stock - assortment-change

            ifelse new-stock <= 0 [
              table:put initial-stock-table food-item 0
              table:put stock-table food-item table:get initial-stock-table food-item
            ]
            ;new-stock != 0
            [table:put initial-stock-table food-item round new-stock
              table:put stock-table food-item table:get initial-stock-table food-item]
            ]

            current-stock = 0 [ ;if a food outlet does not sell either meat or fish
                                ;do nothing, you cannot reduce a stock that does not exists
            ]

            ;if something goes wrong
            [show "I was not able to check if I already sold meat or fish products!"]
          )

          ;show (list "tick" ticks initial-stock-table)


        ]
      ]

    ]
  ]



end



to select-group-and-cook ;household procedure
  ask households [
    if meal-cooked? = true [
      error "Our household is hosting two cooks"
    ]

    ;;procedure to select dinner guests and cook if friendships are turned off
    ifelse friendships? = false [ ;all households have dinner with family members only


      let todays-cook one-of members with [is-cook? = false]  ;select cook
      let todays-dinner-guests members

      ask todays-cook [
        set is-cook? true
        set my-dinner-guests todays-dinner-guests ;gather group for meal - for now this is only the family members, not friends

        ask my-dinner-guests [
          set my-cook todays-cook ;setting todays cook for all dinner-group members
                                  ;print (list who my-cook) ;they all print themselves as my-cook
        ]
      ]
    ]


    ;procedure to select dinner and guests if friendships are turned on ;all household members who are todays-cook and who have friends can invite friends over for dinner
    ; if friendships? = true
    [
      let members-at-home count members with [at-home? = true]

      ifelse members-at-home = 0  [
        set empty-house? true
      ]

      ;if at least 1 member is at home, cook a meal in this household
      [set empty-house? false]

      ;start cooking if someone is at home

      (ifelse empty-house? = true [
        ;do not cook a meal today
        ]

        empty-house? = false [


          let todays-cook one-of members with [is-cook? = false and at-home? = true] ;select cook that is at home
                                                                                     ;show todays-cook

          ;if nobody is at home (anymore), the household will decide no meals will be cooked

          ifelse todays-cook = nobody [
            ;do nothing
          ]
          ;otherwise, proceed
          [

            set meal-cooked? true
            let todays-dinner-guests members

            ask todays-cook [

              set is-cook? true

              let nr-dinner-friends count friendship-neighbors with [at-home? = true and is-cook? = false]


              ;;if the cook has no friends
              ifelse nr-dinner-friends = 0 [
                set my-dinner-guests todays-dinner-guests ;do not invite friends because I do not have any
              ]

              ;;if the cook does have friends
              ;nr-dinner friends != 0
              [

                let dinner-friends-today friendship-neighbors with [at-home? = true and is-cook? = false] ;only invite friends who are still at home and do not have to cook for their own household
                ask dinner-friends-today [
                  set at-home? false
                  move-to patch-here
                ]

                let dinner-members-today family-membership-neighbors with [at-home? = true and is-cook? = false]
                set my-dinner-guests (turtle-set dinner-members-today dinner-friends-today self)

              ]

              ask my-dinner-guests [
                set my-cook todays-cook ;setting todays cook for all dinner-group members

              ]

            ]
          ]
        ]

        ;if something went wrong
        [show "I do not know if there's anyone in me"]
      )

    ]


  ]


  ask persons with [is-cook? = true] [
    let nr-of-dinner-guests count my-dinner-guests
    if nr-of-dinner-guests = 0 [
      error "I have an empty guest list!"
    ]
  ]
end

;;; MEAL SELECTION ;;;

to select-meal ;person procedure to create a shopping list

  ;every meal selection procedure ends with a set shopping list containing one or more meal-to-cook for the cook

  ask persons with [is-cook? = true]  [

    (ifelse meal-selection = "status-based" [
      status-based-meal-selection
      ]

      meal-selection = "majority" [
        majority-based-meal-selection
      ]

      meal-selection = "random" [
        random-meal-selection
      ]

      [
        ;if no meal-selection option has been selected
        print(list who "We do not know how to select our meal!")
      ]

    )

  ]

end

to status-based-meal-selection

  ;;procedure to select status-based a meal
  ask persons with [is-cook? = true and meal-to-cook = "none"] [

    let vip-guest max-one-of my-dinner-guests [status] ;choose guest with highest status; this could in this model version also be himself
    let vip-meal [diet] of vip-guest
    set shopping-list (list vip-meal)

    set meal-to-cook vip-meal   ;cook has decided to cook meal preference of vip-guest
                                ;show (list meal-to-cook)                            ;show meal-to-cook
  ]

end

to majority-based-meal-selection

  ;;procedure to select meal democratically

  let dinner-list-majority [ (list diet) ] of my-dinner-guests
  let freq-list map [ i -> frequency I dinner-list-majority] dinner-list-majority ;creates a list with for each diet on dinner-list-majority how frequent it appears in dinner-list-majority
  let dinner-freq-table table:from-list (map list freq-list dinner-list-majority) ;creates a table with the frequency for each diet on the dinner-list majority
  let count-majority-choice max freq-list ;select the highest count

  let freq-list-unique remove-duplicates freq-list
  let freq-list-sorted sort freq-list-unique

  foreach freq-list-unique [ freq ->

    let selected-meal table:get dinner-freq-table freq
    set shopping-list lput selected-meal shopping-list

  ]

  set meal-to-cook item 0 first shopping-list   ;cook decides what type of meal to prepare

end

to random-meal-selection

  ;;procedure to select meal randomly

  set shopping-list shuffle diets-list ;shuffle the list with diets to create a random shopping list

  let chosen-meal one-of shopping-list ;choose random item from the shopping list
  set meal-to-cook chosen-meal   ;cook decides what type of meal to prepare

end

;;; END OF MEAL SELECTION ;;;

;;; START OF GETTING GROCERIES ;;;

to select-supermarket

  ask persons with [is-cook? = true and meal-to-cook != "none"] [

  ifelse my-supermarket = "none" [
    ;this procedures sets supermarket != "none"
    set my-supermarket first sorted-food-outlets
    set sorted-food-outlets but-first sorted-food-outlets
    ]

  ;if my-supermarket != "none"
     [
      get-groceries
    ]
  ]


end

to get-groceries
  ; All the cooks go get ingredients at the supermarket

  ; Variables
  let length-shopping-list length shopping-list
  let requested-product meal-to-cook
  let available-products "none"
  let available? false
  let neophobic? (neophobia > random-float 1)

  ; Check supermarket product availability
  ask my-supermarket [
    set available-products product-selection
  ]
  set available? member? meal-to-cook available-products

  ; Decision tree based on availability and neophobia
  if not available? [ handle-unavailable-product length-shopping-list neophobic? ]
  if available?     [ handle-available-product requested-product length-shopping-list neophobic? ]

  ; Final step: check-out groceries
  check-out-groceries
end

; Handle cases when the product is unavailable
to handle-unavailable-product [length-shopping-list neophobic?]
  if (neophobic? = false) [
    ifelse (length-shopping-list > 1) [
      get-alternative-groceries
    ] [
      draft-alternative-shopping-list
      select-supermarket
    ]
  ]
  if (neophobic? = true) [
    set supermarket-changes supermarket-changes - 1
    ifelse (supermarket-changes > 0) [
      select-supermarket
    ] [
      handle-exhausted-supermarkets length-shopping-list
    ]
  ]
end

; Handle cases where all supermarkets have been tried
to handle-exhausted-supermarkets [length-shopping-list]
  ifelse (length-shopping-list > 1) [
    get-alternative-groceries
  ] [
    draft-alternative-shopping-list
    select-supermarket
  ]
end

; Handle cases when the product is available
to handle-available-product [requested-product length-shopping-list neophobic?]
  let nr-dinner-guests count my-dinner-guests
  let stock-sufficient? false

  ; Check stock levels for the requested product
  ask my-supermarket [
    let current-stock (table:get stock-table requested-product)
    set stock-sufficient? (current-stock >= nr-dinner-guests)
  ]

  ; Decide actions based on stock availability and neophobia
  if not stock-sufficient? [
    handle-insufficient-stock length-shopping-list neophobic?
  ]
end

; Handle insufficient stock scenarios
to handle-insufficient-stock [length-shopping-list neophobic?]
  ifelse (not neophobic?) [
    if (length-shopping-list > 1) [ get-alternative-groceries ]
  ] [
    ifelse (length-shopping-list > 1) [
      select-supermarket
    ] [
      draft-alternative-shopping-list
    ]
  ]
end


to draft-alternative-shopping-list ;this procedure should take place in the supermarket where the cook is at that moment and include the ingredients that the supermarket offers

  set shopping-list []
  let alternative-shopping-list []

  ask my-supermarket [
    let new-meal one-of product-selection
    set alternative-shopping-list (list new-meal)
  ]

  set shopping-list alternative-shopping-list
  ;show  (list "I set my shopping list to the product selection of my supermarket" shopping-list)
  get-groceries

end

to get-alternative-groceries

  ;show "I am getting alternative groceries"
  set shopping-list remove-item 0 shopping-list
  set meal-to-cook item 0 shopping-list

  set sorted-food-outlets sort-on [distance myself] food-outlets
  set my-supermarket first sorted-food-outlets

  set supermarket-changes length sorted-food-outlets ;to prevent the cook from not being able to get his requested product in the first supermarket of his choice

  get-groceries


end

to check-out-groceries

  let requested-product meal-to-cook
  let nr-dinner-guests count my-dinner-guests

  ask my-supermarket [
    ;cook will reduce the stock of the in which supermarket he purchases his product
    foreach diets-list [ diets ->

      let current-stock (table:get stock-table diets)
      ;show (list diets current-stock)
      (ifelse diets = requested-product [
        table:put stock-table diets ( current-stock - nr-dinner-guests )
        ]
        diets != requested-product [
          table:put stock-table diets current-stock
        ]
        ;if something goes wrong
        [show "I cannot reset my stock"]
      )
    ]

    ;show stock-table
  ]

  ;the cook gets the product and adds his purchase to the sales of the food outlet
  if meal-to-cook != "none" [
    ;show (list requested-product nr-dinner-guests)
    ask my-supermarket [
      let current-sales (table:get sales-table requested-product)
      ;show (list current-sales requested-product)
      table:put sales-table requested-product (current-sales + nr-dinner-guests)
      ;show (list table:get sales-table requested-product requested-product)

    ]

    set bought? true
  ]

end

;;; END OF GETTING GROCERIES;;;

;;; START OF HAVING DINNER ;;;

to cooking

  ask persons with [is-cook? = true]  [

    set my-last-dinner meal-to-cook
    let the-last-dinner meal-to-cook

    ;guests store meal they had and cooking skills of cook
    let my-cooking-skills [cooking-skills] of self

    ask my-dinner-guests [ ;cook asks his guests to set last meal to the meal he cooked
      set my-last-dinner the-last-dinner
      set cooks-cooking-skills my-cooking-skills
    ]
  ]

end

;;; MEAL EVALUATION ;;;

to set-meal-evaluation
  ask households [
    ifelse empty-house? = true [
      ;do not run this procedure
    ]

    ;empty-house = false
    ;run this procedure
    [


      ;set the meal evaluation
      ask members with [is-cook? = true and at-home? = true][
        show (list cooks-cooking-skills meal-quality-variance)
        let my-meals-quality random-normal cooks-cooking-skills meal-quality-variance ;meal quality here is dependent of cooking skills of the cook: cooking skills +/- a hard-coded standard deviation
                                                                                      ;print (list who my-meals-quality is-cook?)
        ask my-dinner-guests [
          set last-meals-quality my-meals-quality
          ;print (list who last-meals-quality is-cook?)

          (ifelse last-meals-quality < 0.55 [
            set last-meal-enjoyment "negative"
          ] last-meals-quality >= 0.55 [
            set last-meal-enjoyment "positive"
          ] [
            ;if no meal evaluation took place
            print "I did not evaluate the meal I just had!"
          ])
        ]
      ]
    ]
  ]

end

to update-diet-preference
  ask households [
    ifelse empty-house? = true [
      ;do not run this procedure
    ]

    ;empty-house = false
    ;run this procedure
    [

      ask members with [at-home? = true][
        ;in this version people consider changing their diet preference after liking a meal several times, depending on their uncertainty avoidance
        (ifelse last-meal-enjoyment = "positive" [

          ;update table with meal enjoyments for each type of diet based on uncertainty avoidance
          let current-meal-enjoyment table:get meal-enjoyments-table my-last-dinner
          let update-meal-enjoyment neophobia > random-float 1 ;this evaluates to FALSE (I am too neophobic to consider liking new foods) to TRUE (I am neophilic enough to consider liking new foods)

          (ifelse update-meal-enjoyment = true [
            table:put meal-enjoyments-table my-last-dinner (current-meal-enjoyment + 1)
            ]
            update-meal-enjoyment = false [
              ;not updating meal-enjoyments
            ]
            ;if something goes wrong
            [show "I was not able to decide if I will update my meal-enjoyments"]
          )

          ;check how often the person has liked the last meal he had and update accordingly (assuming it takes 8-9 times to like a new food, based on literature)
          let nr-meal-enjoyments table:get meal-enjoyments-table my-last-dinner
          if nr-meal-enjoyments >= 8 [
            set diet my-last-dinner
            table:put meal-enjoyments-table my-last-dinner 0
          ]
          ]
          last-meal-enjoyment = "negative" [

            ;do nothing - I did not like the meal that my-cook served me and I will not update my preference
          ]

          ;if something goes wrong
          [show "I do not know if I should change my dietary preference"]
        )
      ]
    ]
  ]

end


to evaluate-meal

  ;dinner guests give status or substract status from their cook if the cook has higher or lower status than themselves
  ;cooks give or substract status from their dinner guests if they liked or disliked the meal, respectively
  ;dinner guests distribute status
  ask persons with [is-cook? = false][

    let my-status status
    let status-of-my-cook [status] of my-cook
    let delta-status abs (my-status - status-of-my-cook)
    let status-change delta-status * status-increment
    ;print (list who my-status my-cook status-of-my-cook)

    (ifelse my-status < status-of-my-cook or my-status = status-of-my-cook [ ;if my cook has a higher status than myself or the same status, I will always show gratitude for the meal, even if I don't like it
      ask my-cook [
        ;print "my status is being increased because my dinner guests liked what I cooked for them"
        set status min (list 1 (status + status-change))
      ]
      ]

      my-status > status-of-my-cook and last-meal-enjoyment = "positive" [
        ask my-cook [
          ;print "my status is being increased because my dinner guests liked what I cooked for them"
          set status min (list 1 (status + status-change))
        ]
      ]

      my-status > status-of-my-cook and last-meal-enjoyment = "negative" [
        ask my-cook [
          ;print ("my status is being reduced because my dinner guests did not like the meal I cooked for them"
          set status max (list 0 (status - status-change)) ;if the cook has lower status than myself and I don't like the meal, I will say so
        ]
      ]



      ;if no input is selected for meal-evaluation, throw error
      [print (list who "I do not know how to evaluate the meal!")]

    )
  ]

  ;cooks distribute status
  ask persons with [is-cook? = true][
    let cooks-status status
    ask my-dinner-guests with [is-cook? = false] [

      let my-status status

      let delta-status abs (my-status - cooks-status)
      let status-change delta-status * status-increment

      (ifelse last-meal-enjoyment = "positive" [
        set status min (list 1 (status + status-change))
        ]

        last-meal-enjoyment = "negative" and cooks-status > my-status [
          ;print "my status is being reduced because I did not like the meal"
          set status max (list 0 (status - status-change))
        ]

        last-meal-enjoyment = "negative" and (cooks-status < my-status or cooks-status = my-status) [ ;when the cooks status is lower or similar to that of the guests and the experience is negative, the cook will still give status
                                                                                                      ;print "my status is being increased because I am considered important by the cook"
          set status min (list 1 (status + status-change))
        ]

        ;if no last-meal-enjoyment
        [print (list who "I do not have an opinion about the last meal I had!")]

      )

    ]
  ]


end

;;; END OF MEAL EVALUATION ;;;

;;; FOOD OUTLETS CHECK SALES AND UPDATE STOCKS ;;;

to check-sales ;food-outlet procedure

  ;determine sales
  ask food-outlets [

    ;print (list who sales)

    ;first check total sales -> if the supermarket did not sell enough products, it will go out of business and hatch a new supermarket with random stock

    let total-sales 0

    foreach diets-list [ diets ->
      let sales-product table:get sales-table diets
      ;show (list diets sales-product)
      set total-sales total-sales + sales-product
    ]

    (ifelse total-sales = 0 [
      set no-sales-count no-sales-count + 1
      ]

      total-sales != 0 [
        set no-sales-count 0
      ]

      ;if sales were not counted
      [show "I could not determine my total sales"]
    )


    ;if the supermarket has had no sales for several weeks, it will go out of business
    (ifelse no-sales-count <= no-sales-threshold [
      ;do nothing - stay in business
      ]

      no-sales-count > no-sales-threshold [ ;before going out of business, create a new supermarket with randomly selected stock
        hatch 1 [
          move-to one-of patches with [not any? turtles-here]
          set opening-day ticks

          ;new supermarket is provided with the same attributes as the supermarket that went out of business, except for stock
          ;provide new supermarket with another assortment and reset all stocks

          ;food-outlet calculates how much of the total population he serves and determines how many products he will offer
          let population-fraction (potential-costumers / count persons)
          let nr-products "none"

          ;based on quantiles of people in this radius compared to total population, food outlet will offer 1-4 different protein sources
          (ifelse population-fraction <= 0.25 [
            set nr-products 1
            ]
            population-fraction > 0.25 and population-fraction <= 0.5 [
              set nr-products 2
            ]
            population-fraction > 0.25 and population-fraction <= 0.75 [
              set nr-products 3
            ]
            population-fraction > 0.75 [
              set nr-products 4
            ]
            ;if calculation of population-fraction did not go right
            [print (list who "I cannot calculate how many products I will offer to my costumers")]
          )

          set product-selection map first rnd:weighted-n-of-list nr-products product-list [ [p] -> last p ] ;based on a weighted list, food outlets choose the products for their shelves

          ;food outlets determine for each product in their product-selection, how much of this product is in stock

          set initial-stock-table table:make
          set sales-table table:make
          set stock-table table:make

          foreach diets-list [ diets ->
            table:put initial-stock-table diets ifelse-value (member? diets product-selection) [
              round (potential-costumers / nr-products)
            ] [
              0
            ]
            table:put sales-table diets 0
            table:put stock-table diets table:get initial-stock-table diets
          ]

          set no-sales-count 0
          set label product-selection
        ]
        let closing-day ticks
        let business-period (closing-day - opening-day)
        set business-duration-list fput business-period business-duration-list
        show ("I close my business")
        die ;supermarket goes out of business

      ]

      ;if the food outlet cannot decide if it sold enough products to stay in business
      [print (list who "I cannot decide if I sold enough to stay in business")]
    )
  ]

end

to update-stock

  let stock-check "none"


  ask food-outlets [
    foreach product-selection [ diets ->
      set stock-check table:get stock-table diets

      ;      if stock-check = 0 and (more-sustainable-shops? = false or less-animal-proteins? = false) [
      ;        show (word "I am out of " diets)
      ;        set stock-check-list fput diets stock-check-list
      ;      ]

    ]


    let nr-assortment length product-selection ;number of products a food outlet offers
    let nr-out-of-stock length stock-check-list

    if nr-assortment = nr-out-of-stock [
      show (list ticks stock-check-list)
      set error? true
    ]
  ]


  ask food-outlets [

    ;if restocking is turned on, supermarkets will restock their assortment based on the sales during the current tick
    ;if restocking is turned off, supermarkets will restock their assortment based on the initial stock set at the start of the run

    (ifelse restocking? = true [

      foreach diets-list [ diets ->

        let initial-stock-diet (table:get initial-stock-table diets)
        let sales-diet (table:get sales-table diets)
        ;show (list sales-diet diets)

        if (initial-stock-diet) != 0 [

          ;calculate how the actual sales of each product relates to the margins set for changing the stock

          let nr-products length product-selection ;number of products a food outlet offers
          let threshold-sales-increase round ( ( upper-margin * initial-stock-diet) ) ;threshold for increasing stock is set at >90% sales of the available stock of this product
          let threshold-sales-decrease round ( ( lower-margin * initial-stock-diet) ) ;threshold for decreasing stock is set at <80% sales of the available stock of this product
          let percentage-sold ( (sales-diet / initial-stock-diet) * 100 ) ;calculate what percentage of the stock is sold
          let lower-margin-sales abs (threshold-sales-decrease - sales-diet) ;how much did the actual sales deviate from the lower threshold-sales, a number set absolute
          let upper-margin-sales abs (threshold-sales-increase - sales-diet) ;
          let shop-size-factor (nr-products / 10)

          (ifelse percentage-sold < threshold-sales-decrease [ ;if sales was below the lower margin sales threshold, reduce the stock
            table:put stock-table diets round ( (initial-stock-diet - (lower-margin-sales * shop-size-factor)) )
            ;show (word "decreasing stock of " diets " from " initial-stock-diet " to " table:get stock-table diets)
            ]

            percentage-sold > threshold-sales-increase [ ;if sales was over the higher margin sales threshold, increase the stock
              table:put stock-table diets round ( (initial-stock-diet + (upper-margin-sales * shop-size-factor)) )
              ;show (word "increasing stock of " diets " from " initial-stock-diet " to " table:get stock-table diets)
            ]

            percentage-sold >= threshold-sales-decrease and percentage-sold <= threshold-sales-increase [
              table:put stock-table diets table:get initial-stock-table diets
              ;show (word "restocking " initial-stock-diet " of " diets)
            ]

            ;if something goes wrong
            [print (list who "I cannot update my stock!")]
          )
          ;show stock-table

        ]

        table:put initial-stock-table diets table:get stock-table diets
      ]
      ]

      restocking? = false [

        foreach diets-list [ diets ->
          table:put stock-table diets table:get initial-stock-table diets
        ]
      ]

      ;if something goes wrong
      [show "I do not know if I should restock based on sales or my initial stock"]
    )

  ]



end

;;; END OF FOOD OUTLETS CHECK SALES AND UPDATE STOCKS ;;;

to visualization
  ask persons [

    ;set size according to status
    (ifelse status <= 0.25 [
      set size 1
      ]
      status > 0.25 and status <= 0.5 [
        set size 1.5
      ]
      status > 0.5 and status <= 0.75 [
        set size 2
      ]
      status > 0.75 and status <= 1 [
        set size 2.5
      ]
      ;if status exceeds 1
      [set size 2]
    )

    ;set color according to diet
    (ifelse diet = "meat" [
      set color 35 ;brown
      ]
      diet = "fish" [
        set color 136 ;pink
      ]
      diet = "vegetarian" [
        set color 44 ;green
      ]
      diet = "vegan" [
        set color 64 ;yellow
      ]
      ;if diet is not set or lost
      [set color 9.9 ;white
        print (list who "I don't have a diet!")
      ]
    )

  ]

end


to prepare-sales-reporter


  ask food-outlets [

    ;show sales-table
    ;show stock-table

    let total-sales 0

    foreach product-selection [ diets ->
      let sales-product table:get sales-table diets
      set total-sales total-sales + sales-product
      table:put report-sales-table diets total-sales
    ]

    ;median sales
    let median-sales-list []
    let median-sales "none"

    foreach product-selection [diets ->
      let sold-product table:get sales-table diets
      set median-sales-list fput sold-product median-sales-list
      set median-sales median median-sales-list
      table:put report-median-sales-table diets median-sales
      ;show report-median-sales-table
    ]

  ]

end

to prepare-stock-reporter

  ask food-outlets [

    ;total stocks
    let total-stock 0

    foreach product-selection [ diets ->
      let stock-product table:get stock-table diets
      set total-stock total-stock + stock-product
      table:put report-stock-table diets total-stock
    ]

    ;median stocks
    let median-stock-list []
    let median-stock "none"

    foreach product-selection [diets ->
      let stock-product table:get stock-table diets
      set median-stock-list fput stock-product median-stock-list
      set median-stock median median-stock-list
      table:put report-median-stock-table diets median-stock
      ;show report-median-stock-table
    ]

  ]

end

to prepare-relative-change-meals-cooked-reporter

  let cooks persons with [is-cook? = true and meal-to-cook != "none"]

  ;set table with meals cooked per tick
  foreach diets-list [diets ->
    let count-meals count cooks with [meal-to-cook = diets]
    table:put report-meals-cooked-table diets count-meals
  ]
  ;print report-meals-cooked-table


  ;set table with difference in meals cooked for the current tick compared to the previous tick
  foreach diets-list [diets ->
    let current-meals-cooked table:get report-meals-cooked-table diets
    ;print current-meals-cooked
    let previous-meals-cooked table:get report-saved-meals-cooked-table diets
    ;print previous-meals-cooked
    let delta-meals-cooked (current-meals-cooked - previous-meals-cooked)
    ;print delta-meals-cooked
    (ifelse previous-meals-cooked = 0 and delta-meals-cooked != 0[
      table:put report-delta-meals-cooked-table diets 1
      ]
      delta-meals-cooked = 0 [
        table:put report-delta-meals-cooked-table diets 0
      ]
      previous-meals-cooked != 0 and delta-meals-cooked != 0 [
        let relative-change-meals-cooked ((delta-meals-cooked / previous-meals-cooked) * 1 )
        ;print relative-change-meals-cooked
        table:put report-delta-meals-cooked-table diets relative-change-meals-cooked
      ]
      ;if something goes wrong
      [show "We cannot calculate the relative change in meals cooked"]
    )
  ]
  ;print report-delta-meals-cooked-table

  ;print (list table:get report-meals-cooked-table "vegan" table:get report-saved-meals-cooked-table "vegan" table:get report-delta-meals-cooked-table "vegan")

  ;set table that remembers the meals cooked at the current tick for the next tick
  foreach diets-list [diets ->
    let count-saved-meals table:get report-meals-cooked-table diets
    table:put report-saved-meals-cooked-table diets count-saved-meals
  ]

end

to prepare-relative-change-dietary-preferences-reporter

  ;set table with dietary preferenes per tick
  foreach diets-list [diets ->
    table:put report-diet-prefs-table diets 0 ;first reset the table so all diets are included in the table with a value
    let count-diet-prefs count persons with [diet = diets]
    table:put report-diet-prefs-table diets count-diet-prefs
  ]
  ;print report-diet-prefs-table

  ;set table with difference in meals cooked for the current tick compared to the previous tick
  foreach diets-list [diets ->
    let current-diet-prefs table:get report-diet-prefs-table diets
    ;print current-meals-cooked
    let previous-diet-prefs table:get report-saved-diet-prefs-table diets
    ;print previous-meals-cooked
    let delta-diet-prefs (current-diet-prefs - previous-diet-prefs)
    ;print delta-diet-prefs
    (ifelse previous-diet-prefs = 0 and delta-diet-prefs != 0 [
      table:put report-delta-diet-prefs-table diets 1 ;when in previous tick no one preferred this diet but in the current tick at least one person does
      ]
      delta-diet-prefs = 0 [
        table:put report-delta-diet-prefs-table diets 0 ;when the number of persons for a dietary preference did not change between ticks
      ]
      previous-diet-prefs != 0 and delta-diet-prefs != 0 [
        let relative-change-diet-prefs ((delta-diet-prefs / previous-diet-prefs) * 1 )
        ;print relative-change-diet-prefs
        table:put report-delta-diet-prefs-table diets relative-change-diet-prefs
      ]
      ;if something goes wrong
      [show "We cannot calculate the relative change in dietary preference"]
    )
  ]
  ;print report-delta-diet-prefs-table

  ;set table that remembers the dietary preferences at the current tick for the next tick
  foreach diets-list [diets ->
    let count-saved-diet-prefs table:get report-diet-prefs-table diets
    table:put report-saved-diet-prefs-table diets count-saved-diet-prefs
  ]

end

to prepare-relative-change-stocks-reporter

  ;set table with stock per tick
  ;use same table as in prepare stock reporter, report-stock-table
  ;print report-stock-table

  ;print (list "current diets" report-diet-prefs-table)


  ;set table with difference in meals cooked for the current tick compared to the previous tick
  foreach diets-list [diets ->
    let current-stock table:get report-stock-table diets
    ;print current-meals-cooked
    let previous-stock table:get report-saved-stock-table diets
    ;print previous-meals-cooked
    let delta-stock (current-stock - previous-stock)
    ;print delta-stock
    (ifelse previous-stock = 0 and delta-stock != 0 [
      table:put report-delta-stock-table diets 1 ;when in previous tick no one preferred this diet but in the current tick at least one person does
      ]
      delta-stock = 0 [
        table:put report-delta-stock-table diets 0 ;when the number of persons for a dietary preference did not change between ticks
      ]
      previous-stock != 0 and delta-stock != 0 [
        let relative-change-stock ((delta-stock / previous-stock) * 1 )
        ;print relative-change-stock
        table:put report-delta-stock-table diets relative-change-stock
      ]
      ;if something goes wrong
      [show "We cannot calculate the relative change in stock"]
    )
  ]
  ;print report-delta-stock-table

  ;set table that remembers the dietary preferences at the current tick for the next tick
  foreach diets-list [diets ->
    let count-saved-stock table:get report-stock-table diets
    table:put report-saved-stock-table diets count-saved-stock
  ]

end



;;;;;;;;;;;;;;;
;; reporters ;;
;;;;;;;;;;;;;;;

;; product selection ;;

to-report nr-of-products
  report [nr-protein-sources] of food-outlets
end


;; status ;;

to-report status-distribution
  report [status] of persons
end

;; cooking skills ;;

to-report cooking-skills-distribution
  report [cooking-skills] of persons
end

;; diet variety ;;

to-report diet-variety-households
  report [diet-diversity] of households
end

to-report diet-variety-networks
  report [network-diet-diversity] of persons
end

;; sales ;;

to-report meat-sales
  let meat-sold table:get report-median-sales-table "meat"
  report meat-sold
end

to-report fish-sales
  let fish-sold table:get report-median-sales-table "fish"
  report fish-sold
end

to-report vegetarian-sales
  let vegetarian-sold table:get report-median-sales-table "vegetarian"
  report vegetarian-sold
end

to-report vegan-sales
  let vegan-sold table:get report-median-sales-table "vegan"
  report vegan-sold
end

;; stocks ;;

to-report meat-stock
  let meat-in-stock table:get report-stock-table "meat"
  report meat-in-stock
end

to-report fish-stock
  let fish-in-stock table:get report-stock-table "fish"
  report fish-in-stock
end

to-report vegetarian-stock
  let vegetarian-in-stock table:get report-stock-table "vegetarian"
  report vegetarian-in-stock
end

to-report vegan-stock
  let vegan-in-stock table:get report-stock-table "vegan"
  report vegan-in-stock
end

;total stocks
to-report total-stocks
  let all-stocks (meat-stock + fish-stock + vegetarian-stock + vegan-stock)
  report all-stocks
end

;; relative change in meals cooked ;;

to-report relative-change-meat-cooked
  let relative-change table:get report-delta-meals-cooked-table "meat"
  report relative-change
end

to-report relative-change-fish-cooked
  let relative-change table:get report-delta-meals-cooked-table "fish"
  report relative-change
end

to-report relative-change-vegetarian-cooked
  let relative-change table:get report-delta-meals-cooked-table "vegetarian"
  report relative-change
end

to-report relative-change-vegan-cooked
  let relative-change table:get report-delta-meals-cooked-table "vegan"
  report relative-change
end

;; relative change in dietary preferences ;;

to-report relative-change-meat-pref
  let relative-change table:get report-delta-diet-prefs-table "meat"
  report relative-change
end

to-report relative-change-fish-pref
  let relative-change table:get report-delta-diet-prefs-table "fish"
  report relative-change
end

to-report relative-change-vegetarian-pref
  let relative-change table:get report-delta-diet-prefs-table "vegetarian"
  report relative-change
end

to-report relative-change-vegan-pref
  let relative-change table:get report-delta-diet-prefs-table "vegan"
  report relative-change
end

;; relative stock changes ;;

to-report relative-change-meat-stock
  let relative-change table:get report-delta-stock-table "meat"
  report relative-change
end

to-report relative-change-fish-stock
  let relative-change table:get report-delta-stock-table "fish"
  report relative-change
end

to-report relative-change-vegetarian-stock
  let relative-change table:get report-delta-stock-table "vegetarian"
  report relative-change
end

to-report relative-change-vegan-stock
  let relative-change table:get report-delta-stock-table "vegan"
  report relative-change
end

;; frequency reporter ;;

to-report frequency [x freq-list]
  report reduce [ [occurrence-count next-item] -> ifelse-value (next-item = x) [occurrence-count + 1] [occurrence-count] ] (fput 0 freq-list)
end
@#$#@#$#@
GRAPHICS-WINDOW
919
165
1537
784
-1
-1
10.0
1
10
1
1
1
0
0
0
1
-30
30
-30
30
0
0
1
days
30.0

BUTTON
20
16
83
49
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
165
16
228
49
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
1558
46
1731
79
initial-nr-households
initial-nr-households
5
5000
95.0
10
1
NIL
HORIZONTAL

BUTTON
92
15
155
48
step
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
6
496
161
556
current-seed
-7.7137065E8
1
0
Number

SWITCH
169
497
282
530
fixed-seed?
fixed-seed?
1
1
-1000

PLOT
416
309
643
456
meals cooked
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"meat" 1.0 0 -6459832 true "" "plot count persons with [meal-to-cook = \"meat\"]"
"fish" 1.0 0 -1664597 true "" "plot count persons with [meal-to-cook = \"fish\"]"
"vegetarian" 1.0 0 -4079321 true "" "plot count persons with [meal-to-cook = \"vegetarian\"]"
"vegan" 1.0 0 -14439633 true "" "plot count persons with [meal-to-cook = \"vegan\"]"

PLOT
415
11
641
158
dietary preferences
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"meat" 1.0 0 -6459832 true "" "plot count persons with [diet = \"meat\"]"
"fish" 1.0 0 -2064490 true "" "plot count persons with [diet = \"fish\"]"
"vegetarian" 1.0 0 -4079321 true "" "plot count persons with [diet = \"vegetarian\"]"
"vegan" 1.0 0 -14439633 true "" "plot count persons with [diet = \"vegan\"]"

PLOT
645
612
916
762
distribution of status
NIL
NIL
0.0
1.1
0.0
10.0
true
false
"" ""
PENS
"default" 0.1 1 -16777216 true "" "histogram(status-distribution)"

CHOOSER
1660
261
1824
306
meal-selection
meal-selection
"status-based" "majority" "random"
0

SLIDER
1558
88
1731
121
mean-family-size
mean-family-size
0
10
2.0
1
1
NIL
HORIZONTAL

SLIDER
1557
127
1730
160
sd-family-size
sd-family-size
0
2
0.0
1
1
NIL
HORIZONTAL

SWITCH
13
93
126
126
friendships?
friendships?
0
1
-1000

TEXTBOX
262
15
399
79
LEGEND\nmeat = brown\nfish = pink\nveget = yellow\nvegan = green
10
0.0
1

PLOT
416
458
643
608
Diet variety in network
NIL
NIL
1.0
5.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram(diet-variety-networks)"

SLIDER
1556
166
1729
199
nr-friends
nr-friends
2
10
6.0
1
1
NIL
HORIZONTAL

SLIDER
1736
208
1909
241
status-increment
status-increment
0
0.1
0.01
0.01
1
NIL
HORIZONTAL

TEXTBOX
16
70
153
88
INITIALIZATION
10
0.0
1

TEXTBOX
13
153
211
179
SCENARIOS & INTERVENTIONS
10
0.0
1

TEXTBOX
13
476
150
494
RUN CONTROLS
10
0.0
1

SLIDER
1740
45
1912
78
initial-nr-food-outlets
initial-nr-food-outlets
1
30
5.0
1
1
NIL
HORIZONTAL

SLIDER
1554
209
1729
242
food-outlet-service-area
food-outlet-service-area
20
60
30.0
5
1
NIL
HORIZONTAL

SWITCH
8
197
165
230
food-outlet-interaction?
food-outlet-interaction?
1
1
-1000

PLOT
414
163
641
307
total food outlet stocks
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -6459832 true "" "plot meat-stock"
"pen-1" 1.0 0 -2064490 true "" "plot fish-stock"
"pen-2" 1.0 0 -4079321 true "" "plot vegetarian-stock"
"pen-3" 1.0 0 -13840069 true "" "plot vegan-stock"

SLIDER
1735
128
1907
161
lower-margin
lower-margin
0
1
0.23
0.01
1
NIL
HORIZONTAL

SLIDER
1734
168
1906
201
upper-margin
upper-margin
0
1
0.8
0.01
1
NIL
HORIZONTAL

SLIDER
1737
87
1909
120
no-sales-threshold
no-sales-threshold
0
365
180.0
10
1
NIL
HORIZONTAL

SWITCH
173
197
271
230
restocking?
restocking?
1
1
-1000

PLOT
645
309
916
457
relative change in meals cooked
NIL
NIL
0.0
10.0
-5.0
5.0
true
false
"" ""
PENS
"pen-1" 1.0 0 -2064490 true "" "plot relative-change-fish-cooked"
"pen-2" 1.0 0 -4079321 true "" "plot relative-change-vegetarian-cooked"
"pen-3" 1.0 0 -13840069 true "" "plot relative-change-vegan-cooked"
"pen-4" 1.0 0 -6459832 true "" "plot relative-change-meat-cooked"

SWITCH
289
498
392
531
error?
error?
1
1
-1000

PLOT
645
12
914
158
relative change in dietary preferences
NIL
NIL
0.0
10.0
-5.0
5.0
true
false
"" ""
PENS
"pen-1" 1.0 0 -2064490 true "" "plot relative-change-fish-pref"
"pen-2" 1.0 0 -4079321 true "" "plot relative-change-vegetarian-pref"
"pen-3" 1.0 0 -13840069 true "" "plot relative-change-vegan-pref"
"pen-4" 1.0 0 -6459832 true "" "plot relative-change-meat-pref"

PLOT
644
162
914
308
relative change in stocks
NIL
NIL
0.0
10.0
-5.0
5.0
true
false
"" ""
PENS
"pen-1" 1.0 0 -2064490 true "" "plot relative-change-fish-stock"
"pen-2" 1.0 0 -4079321 true "" "plot relative-change-vegetarian-stock"
"pen-3" 1.0 0 -13840069 true "" "plot relative-change-vegan-stock"
"pen-4" 1.0 0 -6459832 true "" "plot relative-change-meat-stock"

PLOT
916
11
1123
161
low status - dietary preference
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -6459832 true "" "plot count persons with [diet = \"meat\" and status <= 0.25]"
"pen-1" 1.0 0 -2064490 true "" "plot count persons with [diet = \"fish\" and status <= 0.25]"
"pen-2" 1.0 0 -4079321 true "" "plot count persons with [diet = \"vegetarian\" and status <= 0.25]"
"pen-3" 1.0 0 -13840069 true "" "plot count persons with [diet = \"vegan\" and status <= 0.25]"

PLOT
1124
11
1330
161
high status - dietary preference
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -8431303 true "" "plot count persons with [diet = \"meat\" and status >= 0.75]"
"pen-1" 1.0 0 -2064490 true "" "plot count persons with [diet = \"fish\" and status >= 0.75]"
"pen-2" 1.0 0 -4079321 true "" "plot count persons with [diet = \"vegetarian\" and status >= 0.75]"
"pen-3" 1.0 0 -13840069 true "" "plot count persons with [diet = \"vegan\" and status >= 0.75]"

CHOOSER
8
414
146
459
diet-influencers
diet-influencers
"none" "random" "high-status" "low-status"
0

SLIDER
128
375
300
408
p-influencers
p-influencers
0
1
0.59
0.01
1
NIL
HORIZONTAL

CHOOSER
151
414
289
459
influencers-diet
influencers-diet
"meat" "fish" "vegetarian" "vegan"
3

SWITCH
8
374
124
407
influencers?
influencers?
1
1
-1000

SWITCH
7
270
180
303
more-sustainable-shops?
more-sustainable-shops?
0
1
-1000

SLIDER
8
307
180
340
p-more-sustainable
p-more-sustainable
0
1
0.1
0.01
1
NIL
HORIZONTAL

SWITCH
184
269
357
302
less-animal-proteins?
less-animal-proteins?
0
1
-1000

SLIDER
183
307
356
340
p-less-animal-proteins
p-less-animal-proteins
0
1
0.11
0.01
1
NIL
HORIZONTAL

PLOT
416
612
644
762
Number of products in food outlets
NIL
NIL
1.0
5.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "histogram(nr-of-products)"

PLOT
645
459
915
609
Population vs Stocks
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -5987164 true "" "plot total-stocks"
"pen-1" 1.0 0 -16777216 true "" "plot count persons"

TEXTBOX
1558
19
1708
37
SENSITIVITY ANALYSIS
10
0.0
1

TEXTBOX
13
175
163
193
Supply - demand
10
0.0
1

TEXTBOX
11
246
161
264
Adjust product range at t = 365
10
0.0
1

TEXTBOX
10
352
160
370
Adjust diets at t = 365
10
0.0
1

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="chicken_egg_supply_demand" repetitions="25" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="3650"/>
    <exitCondition>error? = true</exitCondition>
    <metric>current-seed</metric>
    <metric>count persons with [diet = "meat"]</metric>
    <metric>count persons with [diet = "fish"]</metric>
    <metric>count persons with [diet = "vegetarian"]</metric>
    <metric>count persons with [diet = "vegan"]</metric>
    <metric>meat-stock</metric>
    <metric>fish-stock</metric>
    <metric>vegetarian-stock</metric>
    <metric>vegan-stock</metric>
    <metric>count persons with [meal-to-cook = "meat"]</metric>
    <metric>count persons with [meal-to-cook = "fish"]</metric>
    <metric>count persons with [meal-to-cook = "vegetarian"]</metric>
    <metric>count persons with [meal-to-cook = "vegan"]</metric>
    <enumeratedValueSet variable="restocking?">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nr-friends">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="status-increment">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="lower-margin">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-cs-fish">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fixed-seed?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-sales-threshold">
      <value value="180"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-family-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-nr-households">
      <value value="4500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="meal-evaluation">
      <value value="&quot;power-distance&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stock-multiplication-factor">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-nr-food-outlets">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="shops-sustainable?">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-family-size">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-vt">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="upper-margin">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-cs-veget">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-fi">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-cs-vegan">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-outlet-service-area">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-vn">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="meal-quality-variance">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-outlet-interaction?">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-cs?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="price-influence?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-cs-meat">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="friendships?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-me">
      <value value="0.94"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="collectivism-dim">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="meal-selection">
      <value value="&quot;norm-random&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="restocking_servicearea_margins" repetitions="2" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="3650"/>
    <exitCondition>error? = true</exitCondition>
    <metric>current-seed</metric>
    <metric>count persons with [diet = "meat"]</metric>
    <metric>count persons with [diet = "fish"]</metric>
    <metric>count persons with [diet = "vegetarian"]</metric>
    <metric>count persons with [diet = "vegan"]</metric>
    <metric>meat-stock</metric>
    <metric>fish-stock</metric>
    <metric>vegetarian-stock</metric>
    <metric>vegan-stock</metric>
    <metric>count persons with [meal-to-cook = "meat"]</metric>
    <metric>count persons with [meal-to-cook = "fish"]</metric>
    <metric>count persons with [meal-to-cook = "vegetarian"]</metric>
    <metric>count persons with [meal-to-cook = "vegan"]</metric>
    <metric>nr-of-products</metric>
    <steppedValueSet variable="lower-margin" first="0.1" step="0.1" last="0.8"/>
    <steppedValueSet variable="upper-margin" first="0.2" step="0.1" last="0.9"/>
    <steppedValueSet variable="food-outlet-service-area" first="10" step="5" last="60"/>
    <steppedValueSet variable="initial-nr-food-outlets" first="10" step="10" last="100"/>
    <enumeratedValueSet variable="restocking?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fixed-seed?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nr-friends">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="status-increment">
      <value value="0.01"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-cs-fish">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="no-sales-threshold">
      <value value="180"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-family-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-nr-households">
      <value value="4500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="meal-evaluation">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stock-multiplication-factor">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="shops-sustainable?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-family-size">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-vt">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-cs-veget">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-fi">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-cs-vegan">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-vn">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="meal-quality-variance">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-outlet-interaction?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dynamic-cs?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="price-influence?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-cs-meat">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="friendships?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-me">
      <value value="0.94"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="collectivism-dim">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="meal-selection">
      <value value="&quot;norm-random&quot;"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
