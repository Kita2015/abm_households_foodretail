;; version 4.2 ;;

extensions [ rnd table ]


;;;;;;;;;;;;;;;;;;;;;
;; state variables ;;
;;;;;;;;;;;;;;;;;;;;;

breed [ persons person ]
breed  [ households household ]
breed  [ food-outlets food-outlet ]

undirected-link-breed [friendships friendship ] ;assumption: friendships are mutual experiences
undirected-link-breed [family-memberships family-membership]
directed-link-breed [household-memberships household-membership]


globals [
  weighted-diets-list ;weighted list of diets
  diets-list ;list with only diets
  var-product-list ;varied weighted list of products
  product-list ; weighted list of products
  income-levels
  id-households
  total-no-sales-count
  food-outlets-list
  food-outlets-empty-shelves-table
  proteins-empty-shelves-table
  product-counts-table
  report-sales-table
  report-potatoes-table
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
  report-saved-sales-table
  report-delta-sales-table
  business-duration-list
  low-income-affordability-table
  middle-income-affordability-table
  high-income-affordability-table
  diets-affordability-table
  meal-quality-variance
  animal-share
  plant-share
  a-p-ratio
  monitor-duration

]


persons-own [
  meal-enjoyment-table
  diet
  openminded?
  is-cook?
  cooking-skills
  cooks-cooking-skills
  h-id
  dinner-friends
  dinner-members
  shopping-list
  meal-to-cook
  failed-meal
  my-last-dinner
  last-meals-quality
  last-meal-enjoyment?
  my-cook
  my-dinner-guests
  network-diet-diversity
  status
  neophobia
  at-home?
  my-supermarket
  sorted-food-outlets
  basket-full?
  bought?
  supermarket-changes

]

households-own [
  income-level
  id ; identifier
  members
  meal-being-cooked?
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
  diet-sublists-table
  complaints-from-customers
  potatoes-table
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
  reset-ticks
end

to setup-seed
  if not fixed-seed?  [
    set current-seed new-seed
  ]
  random-seed current-seed
end

to setup-globals

  set weighted-diets-list (list (list "meat" 95.1 ) (list  "fish" 1.7 ) (list "vegetarian" 2.6 ) (list "vegan" 0.4 )) ;hard-coded values of dietary identities in the Netherlands
  set diets-list (list "meat" "fish" "vegetarian" "vegan")
  set product-list (list (list "meat" 0.6) (list "fish" 0.6) (list "vegetarian" 0.6) (list "vegan" 0.4) ) ;hard-coded values based on a report by Eiweet monitor
  set id-households 0
  set total-no-sales-count 0
  set food-outlets-empty-shelves-table  table:make
  set proteins-empty-shelves-table table:make
  set product-counts-table table:make
  set food-outlets-list []
  set report-sales-table table:make
  set report-potatoes-table table:make
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
  set report-saved-sales-table table:make
  set report-delta-sales-table table:make
  set business-duration-list []
  set meal-quality-variance 0.1 ;hard-coded 10% standard deviation of a cook's cooking skills

  foreach diets-list [ diets ->
    table:put report-sales-table diets 0
    table:put report-stock-table diets 0
    table:put report-meals-cooked-table diets 0
    table:put report-saved-meals-cooked-table diets 0
    table:put report-delta-meals-cooked-table diets 0
    table:put report-saved-diet-prefs-table diets 0
    table:put report-delta-diet-prefs-table diets 0
    table:put report-saved-stock-table diets 0
    table:put report-delta-stock-table diets 0
    table:put report-saved-sales-table diets 0
    table:put report-delta-sales-table diets 0
    table:put proteins-empty-shelves-table diets 0
  ]

      table:put report-potatoes-table "potatoes" 0

  set a-p-ratio "none" ;is to be set in setup-food-outlets
  set monitor-duration 0


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

    let new-family random-poisson 2.1 ;hard-coded mean
    let new-family-abs abs round new-family
    hatch-persons new-family-abs + 1
    set empty-house? false
    set meal-being-cooked? false
    set diet-diversity 0
    set vip-preference "none"

  ]

  if debug? [
    ;check: no more than one house per patch
    ask patches with [count households-here > 1] [
      show (word "more than one house here!")
    ]
  ]
end

to setup-persons
  ask persons [
    ;set age random-normal 41 25 ; mean and sd are chosen based on Dutch demographic data
    set shape "person"
    set color pink
    set meal-enjoyment-table table:make
    set diet first rnd:weighted-one-of-list weighted-diets-list [ [p] -> last p ]
    set openminded? true



    foreach diets-list [ diets ->
      table:put meal-enjoyment-table diets 0
    ]

    let initial-diet-enjoyment random-float 1
    table:put meal-enjoyment-table diet initial-diet-enjoyment

    let other-enjoyments []
    set other-enjoyments remove diet diets-list
    if debug? [
    show (word "My diet: " diet " and my other enjoyments " other-enjoyments)
    ]


    foreach other-enjoyments [ diets ->
      let enjoyment random-float initial-diet-enjoyment
      table:put meal-enjoyment-table diets enjoyment
    ]

    set is-cook? false
    set shopping-list []
    set meal-to-cook "none"
    set failed-meal "none"
    set cooking-skills random-float 1
    ;set cooking-skills ofat-cooking-skills
    set status random-float 1
    ;set status ofat-status
    set neophobia random-float 1
    ;set neophobia ofat-neophobia
    set my-last-dinner "none"
    set last-meals-quality "none"
    set last-meal-enjoyment? false

    set network-diet-diversity 0
    set cooks-cooking-skills 0
    set my-cook "nobody"
    set my-dinner-guests "nobody"
    set my-supermarket "none"
    set basket-full? false
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

    ask persons [
      let potential-friends other persons with [h-id != [h-id] of myself]
      let nr-friendships random nr-friends
      repeat nr-friendships [create-friendship-with one-of potential-friends [set color 9.9]]
      set dinner-friends friendship-neighbors ;this should be an agentset
      set label count dinner-friends
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
    set diet-sublists-table table:make
    set complaints-from-customers table:make

    foreach diets-list [ diets ->
      table:put diet-sublists-table diets []
      table:put complaints-from-customers diets 0
      table:put product-counts-table diets 0
    ]

    if debug? [
      show (word "Our diet-sublists-table: " diet-sublists-table)
    ]

    set potatoes-table table:make
    table:put potatoes-table "potatoes" 0

    ;food-outlet counts number of persons in certain radius
    set potential-costumers count persons in-radius food-outlet-service-area

    set initial-stock-table table:make
    set sales-table table:make
    set stock-table table:make

      ;provide each food outlet with a stock based on the reported values in Eiweet monitor and add a 10% safety stock


      ; Initialize a initial stock table

    ; Distribute initial stocks based on potential customers and animal:plant ratio market share in Dutch supermarkets in 2023
    ;create reported variation in animal:plant market sales

    let min-plant random-float 0.35
    let dif-plant random-float (0.53 - 0.35) ;difference between 35% and 53% plant-based market share
    let var-plant min-plant + dif-plant ;resulting in a number between 0.35 and 0.53
    let var-animal 1 - var-plant

    ;normalize the values
    let total-animal-plant (3 * var-animal) + var-plant
    let p-plant var-plant / total-animal-plant
    let p-animal var-animal / total-animal-plant


    set var-product-list (list (list "meat" p-animal) (list "fish" p-animal) (list "vegetarian" p-animal) (list "vegan" p-plant) ) ;varied values based on a report by Eiweet monitor

      foreach var-product-list [ diet-weight-pair ->
        let diet-type first diet-weight-pair  ; Extract diet name (e.g., "meat")
        let weight last diet-weight-pair      ; Extract weight value
        let estimated-customers round (potential-costumers * weight + (potential-costumers * weight * 0.1))  ; set stock including 10% safety stock

        ; Store result in table
        table:put initial-stock-table diet-type estimated-customers
      ]

      ; Show the table to verify
      if debug? [
    show initial-stock-table
    ]

    foreach diets-list [ diets ->
      table:put sales-table diets 0
      table:put stock-table diets table:get initial-stock-table diets
    ]
    set no-sales-count 0
    set product-selection diets-list
    set label (list potential-costumers product-selection)
    set nr-protein-sources length product-selection

  ;set a-p-ratio at t=0
  ;add up all animal and plant based items for all food outlets

    let animal-list ["meat" "fish" "vegetarian"]
    let count-animal-items 0
    let count-plant-items 0

  foreach animal-list [product ->
      let count-a-items table:get stock-table product
      set count-animal-items count-animal-items + count-a-items
      if debug? [
        show (word "count animal items " count-animal-items)
      ]
    ]

    let count-p-items table:get stock-table "vegan"
    set count-plant-items count-plant-items + count-p-items
    if debug? [
    show (word "count plant items " count-plant-items)
    ]

    let norm-animal-items round ( (count-animal-items / (count-animal-items + count-plant-items )) * 100 )
    let norm-plant-items round ( (count-plant-items / (count-animal-items + count-plant-items )) * 100 )

    set animal-share norm-animal-items
    set plant-share norm-plant-items

    set a-p-ratio count-animal-items / count-plant-items
    if debug? [
    show (word "a-p-ratio: " a-p-ratio " count animal items normalized: " norm-animal-items " count plant items normalized: " norm-plant-items)
    ]







  ]




  ask persons [
    set sorted-food-outlets sort-on [distance myself] food-outlets
    ifelse initial-nr-food-outlets <= 2 [
      set supermarket-changes initial-nr-food-outlets
      if debug? [
        show (word "I am following the rules for setting supermarket-changes, which are: " supermarket-changes)
      ]
    ]
    [
    set supermarket-changes 3
   ]
  ]

  set food-outlets-list [who] of food-outlets

  foreach food-outlets-list [ fo ->
    table:put  food-outlets-empty-shelves-table fo []
  ]
  if debug? [
  print food-outlets-empty-shelves-table
  ]


end


;;;;;;;;;
;; RUN ;;
;;;;;;;;;

to go

  if ticks = 3650 or error? = true [stop]

  if change-diets? = true and ticks > 730 [
    if debug? [
    print "setting monitor duration + 1"
    ]
  set monitor-duration monitor-duration + 1
  ]

  closure-of-tick

  ;interventions
  intervention-diets
  ;change-plant-protein ;executed through check-restocking-tables procedure
  ;change-animal-protein ;executed through check-restocking-tables procedure

  ;start having dinner
  select-group-and-cook

  ;ask cooks
  select-meal
  obtain-groceries

  ;ask persons
  cooking
  set-meal-evaluation
  update-diet-preference
  evaluate-meal
  normalize-status

  ;interface visuals
  visualization

  ;ask food outlets
  check-sales-tables
  check-restocking-tables



  ;reporters
  prepare-sales-reporter
  prepare-stock-reporter
  prepare-relative-change-meals-cooked-reporter
  prepare-relative-change-dietary-preferences-reporter
  prepare-relative-change-stocks-reporter
  prepare-relative-change-sales-reporter


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
    set failed-meal "none"
    set is-cook? false
    set my-dinner-guests "nobody"
    set my-cook "nobody"
    set cooks-cooking-skills "none"
    set last-meals-quality "none"
    set last-meal-enjoyment? false
    set bought? false

    let network-members (turtle-set self dinner-friends dinner-members) ;
    let diets-network [ (list diet) ] of network-members
    let unique-diets-network remove-duplicates diets-network
    let count-diets-network length(unique-diets-network)
    set network-diet-diversity count-diets-network
  ]

  ask persons [
    set sorted-food-outlets sort-on [distance myself] food-outlets
    ifelse initial-nr-food-outlets <= 2 [
      set supermarket-changes initial-nr-food-outlets
      if debug? [
        show (word "I am following the rules for setting supermarket-changes, which are: " supermarket-changes)
      ]
    ]
    [
      set supermarket-changes 3
    ]
  ]

  ask households [
    set meal-being-cooked? false
    set empty-house? false
    let diets-members [ (list diet) ] of members
    let unique-diets remove-duplicates diets-members
    let count-diets length(unique-diets)
    set diet-diversity count-diets
  ]

  foreach diets-list [ diets ->
    table:put report-stock-table diets 0
    table:put report-sales-table diets 0
  ]


  ask food-outlets [
    table:put potatoes-table "potatoes" 0
    foreach diets-list [ diets ->
      table:put sales-table diets 0
      table:put complaints-from-customers diets 0
    ]

    foreach food-outlets-list [ fo ->
      table:put  food-outlets-empty-shelves-table fo []
    ]
  ]

  foreach diets-list [diets ->
    table:put report-delta-meals-cooked-table diets 0
    table:put report-delta-diet-prefs-table diets 0
    table:put report-delta-stock-table diets 0
  ]






end

to intervention-diets

  ifelse change-diets? = false [
    ; do not run this procedure
  ]

  ;if change-diets? = true
  [

    ifelse monitor-duration = intervention-duration [
      ;the intervention will be terminated


      if debug? [
      print "terminating intervention"
      ]
      set change-diets? false
      ask persons with [openminded? = false ] [
        set openminded? true

      ]

    ]

    ;if the intervention duration has not passed yet, proceed with the intervention
    [

      ifelse ticks = 730 [




        (ifelse influencers = "random" [

          let count-persons count persons
          let nr-influencers p-influencers * count-persons
          let influencers-group n-of nr-influencers persons


          ask influencers-group [
            table:put meal-enjoyment-table influencers-diet 1
            set diet influencers-diet
            set openminded? false
            show (word "Changing my diet to " influencers-diet)
          ]



          ]

          influencers = "low-status" [

            let low-status-persons persons with [status <= status-tail]

            let count-low-status-persons count low-status-persons
            print count-low-status-persons
            let nr-influencers p-influencers * count-low-status-persons
            print nr-influencers
            let influencers-group n-of nr-influencers low-status-persons
            print influencers-group


            ask influencers-group [
              table:put meal-enjoyment-table influencers-diet 1
              set diet influencers-diet
              set openminded? false
              show (word "Changing my diet to " influencers-diet)

            ]


          ]



          influencers = "high-status" [
            let high-status-persons persons with [status >= status-tail]
            let count-high-status-persons count high-status-persons
            let nr-influencers p-influencers * count-high-status-persons
            let influencers-group n-of nr-influencers high-status-persons

            ask influencers-group [
              table:put meal-enjoyment-table influencers-diet 1
              set diet influencers-diet
              set openminded? false
              show (word "Changing my diet to " influencers-diet)
            ]

          ]

          ;if something goes wrong
          [print "The model was not able to use influencers to change dietary preference of part of the population"]
        )

      ]
      ;if influencers = true but ticks != 730, we are not changing diets
      [
        ;do nothing
      ]
    ]
  ]





end

to change-plant-protein





      if debug? [
      show (word "Changing plant protein stock! at tick " ticks)
      ]

      let sustainable-foods []
        set sustainable-foods (list "vegan")

        ;update sustainable stocks
        foreach sustainable-foods [ food-item ->

          let current-stock table:get initial-stock-table food-item

          if current-stock = 0 and p-change-plant-protein > 0 [

            ;if the food outlet did not sell vegetarian and vegan before it will now start selling some products
            let assortment-change round ((business-orientation * potential-costumers * p-change-plant-protein))

            if debug? [
              show (word "before change plant proteins if current stock = 0, our initial stock table " initial-stock-table)
            ]
            table:put initial-stock-table food-item round assortment-change

            table:put stock-table food-item table:get initial-stock-table food-item

            if debug? [
              show (word "after change plant proteins if current stock = 0, our new initial stock table "  initial-stock-table)
            ]
          ]



        if current-stock = 0 and p-change-plant-protein < 0 [

          ;if the food outlet did not sell vegetarian and vegan before it will not reduce selling these products.
          ;do nothing
        ]


        if current-stock != 0
        [
          ;the food outlet has sold vegetarian and vegan before and will adjust the quantities of these products

          if debug? [
            show (word "before change plant proteins if current stock != 0, our initial stock table " initial-stock-table)
          ]

          let assortment-change round ((business-orientation * current-stock * p-change-plant-protein) )

          if debug? [
          show (word food-item " change plant protein assortment-change " assortment-change)
          ]
          let new-assortment (current-stock + assortment-change)
          ifelse new-assortment > 0 [
            table:put initial-stock-table food-item new-assortment
            table:put stock-table food-item table:get initial-stock-table food-item
            if debug? [
              show (word "after change plant proteins if we sold vega(n) before, our new initial stock table" initial-stock-table)
            ]
          ]


              ;if new-assortment < 0 ;the product will be set to 0, meaning it is not available
              [
                table:put initial-stock-table food-item 0
                table:put stock-table food-item 0
                if debug? [
                show (word "after change plant proteins preventing negative stock, our initial stock table "  initial-stock-table)
                ]
              ]

            ]



      ;update labels of food outlet

      let current-product-selection []
      foreach diets-list [ diets ->
        let current-availability table:get stock-table diets

        ifelse current-availability != 0 [
          set current-product-selection lput diets current-product-selection
        ]
        ;if the product is not offered
        [
          ;do nothing
        ]
      ]

        set label (list potential-costumers current-product-selection)
        set product-selection current-product-selection
        set nr-protein-sources length product-selection
      ]



end

to change-animal-protein



      let unsustainable-foods []

      set unsustainable-foods (list "meat" "fish" "vegetarian")

        ;update sustainable stocks
        foreach unsustainable-foods [ food-item ->

          let current-stock table:get initial-stock-table food-item

          if current-stock = 0 and p-change-animal-protein > 0 [

            ;if the food outlet did not sell vegetarian and vegan before it will now start selling some products
            let assortment-change (business-orientation * potential-costumers * p-change-animal-protein)
            table:put initial-stock-table food-item round (assortment-change)
            table:put stock-table food-item table:get initial-stock-table food-item

            ;if debug? [
              show (word "after change animal proteins if current stock = 0, tick" ticks initial-stock-table)
            ;]
          ]


          if current-stock = 0 and p-change-animal-protein < 0 [

            ;if the food outlet did not sell vegetarian and vegan before it will still not sell these products.
            ;do nothing
          ]


            if current-stock != 0
            [
          ;the food outlet has sold vegetarian and vegan before and will adjust the quantities of these products
          ;    let assortment-change round ( (business-orientation * potential-costumers * p-change-animal-protein) )
          let assortment-change round ( (business-orientation * current-stock * p-change-animal-protein) )
          if debug? [
            show (word food-item " change animal protein assortment-change " assortment-change)
          ]
          let new-assortment (current-stock + assortment-change)
              ifelse new-assortment > 0 [
                table:put initial-stock-table food-item new-assortment
                table:put stock-table food-item table:get initial-stock-table food-item
                if debug? [
                show (word "after change animal proteins if we sold vega(n) before, tick" ticks initial-stock-table)
                ]
              ]

              ;ifelse new-assortment < 0 the product will be set to 0, meaning it is not available
              [
                table:put initial-stock-table food-item 0
                table:put stock-table food-item 0
                if debug? [
                show (word "after change animal proteins preventing negative stock, tick" ticks initial-stock-table)
                ]
              ]

            ]
          ]





        ;update labels of food outlet

          let current-product-selection []
          foreach diets-list [ diets ->
            let current-availability table:get stock-table diets

            ifelse current-availability != 0 [
              set current-product-selection lput diets current-product-selection
            ]
            ;if the product is not offered
            [
              ;do nothing
            ]
      ]
      if debug? [
        show (word "changing label to " current-product-selection)
      ]

      set label (list potential-costumers current-product-selection)
      set product-selection current-product-selection
      set nr-protein-sources length product-selection






end



to select-group-and-cook ;household procedure
  ask households [
    if meal-being-cooked? = true [
      show "Our household is hosting two cooks"
      set error? true
    ]


    ;procedure to select dinner and guests if friendships are turned on ;all household members who are todays-cook and who have friends can invite friends over for dinner
    ; if friendships? = true

    let members-at-home count members with [at-home? = true]

    ifelse members-at-home = 0  [
      set empty-house? true
    ]

    ;if at least 1 member is at home, cook a meal in this household
    [
      set empty-house? false
    ]

    ;start cooking if someone is at home

    (ifelse empty-house? = true [
      ;do not cook a meal today
      ]

      empty-house? = false [


        let todays-cook one-of members with [is-cook? = false and at-home? = true] ;select cook that is at home


        ;if nobody is at home (anymore), the household will decide no meals will be cooked

        ifelse todays-cook = nobody [
          ;do nothing
        ]
        ;otherwise, proceed
        [


          let dinner-members-today members

          ask todays-cook [

            set is-cook? true
            let p-invite-friends random-float 1

            ifelse p-invite-friends <= neophobia [
              ;not inviting friends

              if debug? [
              show (word "No way, I am NOT inviting friends today at tick = " ticks)
              ]
              set my-dinner-guests dinner-members-today ;do not invite friends because the cook only wants to eat by himself / with family members
              ask my-dinner-guests [
                set my-cook todays-cook ;setting todays cook for all dinner guests
              ]

            ]

            ;if p-invite-friends > neophobia, the cook will invite friends
            [
              if debug? [
              show (word "Yes, I am inviting friends today at tick = " ticks)
              ]
            ]

              let nr-dinner-friends count friendship-neighbors with [at-home? = true and is-cook? = false]


              ;;if the cook has no friends
              ifelse nr-dinner-friends = 0 [
                set my-dinner-guests dinner-members-today ;do not invite friends because I do not have any available friends today
              if debug? [
                show (word "I cannot invite friends today, all of them are occupied, or I don't have any friends, it's just me (and my family) " my-dinner-guests " at tick = " ticks)
                 ]
              ]

              ;;if the cook does have friends
              ;nr-dinner friends != 0
              [

                let dinner-friends-today friendship-neighbors with [at-home? = true and is-cook? = false] ;only invite friends who are still at home and do not have to cook for their own household

                if debug? [
                show dinner-friends-today
                 ]
                ask dinner-friends-today [
                  set at-home? false
                  move-to patch-here
                ]

                ;let dinner-members-today family-membership-neighbors with [at-home? = true and is-cook? = false] -> Could be necessary if persons in the turtle set dinner-members-today have been claimed by cooks in other households
                set my-dinner-guests (turtle-set dinner-members-today dinner-friends-today self)
                 if debug? [
                show (word "My dinner guests, friends and family " my-dinner-guests " " dinner-members-today " " dinner-friends-today " " self)
              ]

              ]

              ask my-dinner-guests [
                set my-cook todays-cook ;setting todays cook for all dinner guests

              ]
            ]

          ]
        set meal-being-cooked? true
        ]





      ;if something went wrong
      [show "I do not know if there's anyone in me"]
    )




  ]



  ask persons with [is-cook? = true] [
    let nr-of-dinner-guests count my-dinner-guests

    if debug? [
    show (word "My number of dinner guests " nr-of-dinner-guests " and my guests " my-dinner-guests)
     ]

    if nr-of-dinner-guests = 0 [
      show "I have an empty guest list!"
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

  set meal-to-cook item 0 one-of shopping-list   ;cook decides what type of meal to prepare

end

to random-meal-selection

  ;;procedure to select meal randomly

  set shopping-list shuffle diets-list ;shuffle the list with diets to create a random shopping list

  let chosen-meal one-of shopping-list ;choose random item from the shopping list
  set meal-to-cook chosen-meal   ;cook decides what type of meal to prepare

end

;;; END OF MEAL SELECTION ;;;

;;; START OF GETTING GROCERIES ;;;

to obtain-groceries

  ask persons with [is-cook? = true] [
    if debug? [
    show (word "Starting groceries! at tick = " ticks)
    ]

      while [bought? = false ]
    [

    ifelse supply-demand = "static-restocking" or supply-demand = "dynamic-restocking" [



      ask persons with [is-cook? = true and meal-to-cook != "none" and my-supermarket = "none" and basket-full? = false and bought? = false] [
        if debug? [
        show "obtain groceries I am selecting my supermarket"
        ]

        ifelse supermarket-changes >= 1 and supermarket-changes <= 3 [ ;so supermarket changes is 1,2 or 3
          if debug? [
          show (word "obtain My supermarket changes are: " supermarket-changes)
          ]
          select-supermarket ;if the cook cannot change supermarket, he is referred to get-alternative-groceries
        ]
        ;if the cook is at his last supermarket
        [
          if debug? [
            show "obtain groceries No more supermarkets to try; looking for alternative groceries"
          ]
          get-alternative-groceries]

      ]

      ask persons with [is-cook? = true and meal-to-cook != "none" and my-supermarket != "none" and basket-full? = false and bought? = false] [
        if debug? [
          show (word " obtain groceries I am getting groceries at: " my-supermarket)
        ]
        get-groceries
      ]


      ask persons with [is-cook? = true and meal-to-cook != "none" and my-supermarket != "none" and basket-full? = true and bought? = false] [
        if debug? [
          show (word "obtain groceries My basket is full: " basket-full? " and I am checking out, buying: " meal-to-cook)
        ]
        check-out-groceries
      ]




      ]

      ;if supply-demand = "infinite-stock"
      [
        if debug? [
          show "obtain groceries Skipping groceries, we eat from heaven (The model simulates household interaction only.)"
        ]
        set bought? true
      ]
    ]
  ]




end

to select-supermarket


  ; This procedure sets supermarket != "none"
  if debug? [
    show (word "select supermarket This is my list of supermarkets: " sorted-food-outlets)
  ]
  set my-supermarket first sorted-food-outlets
  set supermarket-changes supermarket-changes - 1
  set sorted-food-outlets but-first sorted-food-outlets
  if debug? [
    show (word "select-supermarket My new supermarket is: " my-supermarket)
  ]


end

to get-groceries

  ; All the cooks go get ingredients at the supermarket

  ; Variables
  let requested-product meal-to-cook
  let available-products "none"
  let available? false
  let neophobic? (neophobia > random-float 1)

  ; Check supermarket product availability
  ask my-supermarket [
    set available-products product-selection
  ]
  set available? member? meal-to-cook available-products

  let nr-dinner-guests count my-dinner-guests
  let stock-sufficient? "none"

  ; Check stock levels for the requested product
          ask my-supermarket [
          let current-stock (table:get stock-table requested-product)
          ifelse (current-stock >= nr-dinner-guests) [

            set stock-sufficient? true
          ] [
      if debug? [
      show (word "get groceries current stock of: " requested-product " is " current-stock)
      ]
            set stock-sufficient? false
          ]
        ]

  ; Decision tree for availability and sufficient stock
  if available? = true and stock-sufficient? = true  [
    if debug? [
    show (word "get groceries My product is available: " meal-to-cook " at " my-supermarket)
    ]
    set basket-full? true
     ]

  if not available? or stock-sufficient? = false [

    ;the cook files a complaint at the supermarket because he cannot purchase his desired ingredient. This way, the supermarkets are aware of the limitations of their stock.

      if debug? [
    show (word "get  groceries I cannot buy MY protein source:  "meal-to-cook " here for " nr-dinner-guests " at " my-supermarket)
  ]

    let protein-complaint meal-to-cook

;  ask my-supermarket [
;
;      let current-nr-complaints table:get complaints-from-customers protein-complaint
;      table:put complaints-from-customers protein-complaint (current-nr-complaints + nr-dinner-guests)
;          if debug? [
;      show (word "Complaints we have received so far: " complaints-from-customers)
;    ]
;    ]


    if debug? [
    show (word "get groceries My product is NOT sufficiently available: " nr-dinner-guests " of " meal-to-cook " at " my-supermarket)
    ]
    ifelse neophobic? = false [
    if debug? [
      show "get groceries I am NOT neophobic and will get alternative groceries"
      ]
      get-alternative-groceries
    ] [
      ifelse neophobic? = true and supermarket-changes >= 1 and supermarket-changes <= 3 [
        if debug? [
          show (word "get groceries I am neophobic and will chose another supermarket, my supermarket changes are: " supermarket-changes)
        ]
        select-supermarket]

      ;if supermarket-changes is < 1
      [
        if debug? [
          show (word "get groceries I am neophobic but I cannot switch supermarket so I'll get alternative groceries,  my supermarket changes are: " supermarket-changes)
        ]
        get-alternative-groceries]
    ]
  ]



end

to get-alternative-groceries ;this procedure takes place in the supermarket where the cook is at that moment and includes the ingredients that the supermarket offers

  set shopping-list []
  let alternative-shopping-list []
  let nr-dinner-guests count my-dinner-guests
  let sufficient-stock? false

  ;set alternative shopping list
  ask my-supermarket [
    set alternative-shopping-list product-selection

  ]

  let stock-table-alternative-groceries table:make

  ; ask the supermarket to provide stock for each item in the alternative-shopping-list and put the results in a table
  if debug? [
    show (word "My alternative shopping list: " alternative-shopping-list)
  ]
  foreach alternative-shopping-list [protein ->
    ask my-supermarket [
      let current-stock table:get stock-table protein
      table:put stock-table-alternative-groceries protein current-stock

    ]
  ]

  if debug? [
    show (word "get-alternative groceries Stock-table-alternative-groceries: " stock-table-alternative-groceries)
  ]

  let sufficient-stock-list []

  ; loop through the shopping list and compare stock with nr-dinner-guests and create a list with proteins that are sufficiently in stock
  foreach alternative-shopping-list [protein ->
    let current-stock table:get stock-table-alternative-groceries protein
    ifelse current-stock >= nr-dinner-guests [
      if debug? [
        show (word "get alternative groceries Sufficient stock found for: " protein)
      ]
      set sufficient-stock? true
      set sufficient-stock-list lput protein sufficient-stock-list
      if debug? [
        show (word "get-alterantive-groceries Sufficient-stock-list: " sufficient-stock-list)
      ]
    ]
    [
      ;all products offered have insufficient stock
      if debug? [
        show (word "get alternative groceries current stock of: " protein " is " current-stock)
      ]
      if debug? [
        show (word "get alternative groceries Insufficient stock for: " protein)
      ]
    ]
  ]

  let length-sufficient-stock-list length sufficient-stock-list

  ifelse length-sufficient-stock-list > 0 [
    set meal-to-cook one-of sufficient-stock-list
    set basket-full? true
   if debug? [
  show (word "get alternative groceries My basket is full and I am checking out:" my-dinner-guests " " meal-to-cook)
  ]
  check-out-groceries
]
;if the supermarket does not have any protein products left, the cook will buy a non-protein product and notifies management of the supermarket they stocks are too limited
[
  if debug? [
    show (word "get alternative groceries I cannot buy ANY protein source here for " nr-dinner-guests " at " my-supermarket)
  ]

    let protein-complaint one-of alternative-shopping-list
    set failed-meal protein-complaint
      if debug? [
    show (word "get alternative groceries I am complaining about // "nr-dinner-guests " "  protein-complaint  " at " my-supermarket " \\but I could have complained about all these: " alternative-shopping-list)
  ]

  ask my-supermarket [

      let current-nr-complaints table:get complaints-from-customers protein-complaint
      table:put complaints-from-customers protein-complaint (current-nr-complaints + nr-dinner-guests)
          if debug? [
      show (word "Complaints we have received so far: " complaints-from-customers)
    ]
    ]


  set meal-to-cook "potatoes"
  set basket-full? true
  if debug? [
    show (word "I am unfortunately buying: " meal-to-cook " and I am going to check out my groceries")
  ]
  check-out-groceries


  ]


end


to check-out-groceries

  ifelse supply-demand = "dynamic-restocking" or supply-demand = "static-restocking" [

    let requested-product meal-to-cook
    let nr-dinner-guests count my-dinner-guests
    let check-stock "none"

    ifelse meal-to-cook != "potatoes" [
      ;check if the stock is still sufficient. If yes, proceed with check-out. If not, return to the aisles.
      ask my-supermarket [
        set check-stock table:get stock-table requested-product
        if debug? [
        show (word "My customer needs " nr-dinner-guests " of " requested-product " I have " check-stock " in stock.")
        ]
      ]

      ifelse check-stock >= nr-dinner-guests [

        ask my-supermarket [
          ;cook will reduce the stock of the in which supermarket he purchases his product
          foreach diets-list [ diets ->

            let current-stock (table:get stock-table diets)


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


          if debug? [
            show (word "Our stock table: " stock-table)
          ]
        ]

        ;extra check for supermarkets in the rare cases they run out of stock of one or more protein sources

        ;the cook gets the product and adds his purchase to the sales of the food outlet
        if meal-to-cook != "none" [
          if debug? [
            show (word "check-out-groceries This is what I want to buy: " requested-product " for this number of guests: " nr-dinner-guests)
          ]
          ask my-supermarket [
            let current-sales (table:get sales-table requested-product)
            if debug? [
              show (word "checking-out-groceries This is our current sales :" current-sales " for " requested-product)
            ]
            table:put sales-table requested-product (current-sales + nr-dinner-guests)
            let new-sales (table:get sales-table requested-product)
            if debug? [
              show (word "checking-out-groceries This is our sales after customer check-out :" new-sales " for " requested-product)
            ]

          ]
        ]

        if debug? [
          show (word "I just bought groceries - before check-out, bought = " bought?)
        ]
        set bought? true
        if debug? [
          show (word "check-out-groceries I just bought = " bought? meal-to-cook " for " nr-dinner-guests)
        ]
      ]

      ;if stock is not sufficient at check-out:
      [
        if debug? [
        show (word "At check-out my product was sold-out :" meal-to-cook " for " my-dinner-guests)
        ]
        set basket-full? false
      ]

    ]


      ;if the cook had to buy potatoes:
      [
        ask my-supermarket [
          ;only recording sales because we assume that the supermarket has infinite stock of potatoes
          let current-sales-potatoes (table:get potatoes-table requested-product)
          table:put potatoes-table requested-product (current-sales-potatoes + nr-dinner-guests)

        ]
        set bought? true
        if debug? [
          show (word "check-out-groceries I just bought = " bought? meal-to-cook " for " nr-dinner-guests)
        ]

      ]

  ]

  ;if supply-demand = "infinite-stock"
  [
    ;no need to keep track of stocks reduced by people buying as the shops will restock using initial stock every time step; only tracking sales would be enough
  ]




end

;;; END OF GETTING GROCERIES;;;

;;; START OF HAVING DINNER ;;;

to cooking

  ask persons with [is-cook? = true and bought? = true]  [

    set my-last-dinner meal-to-cook
    let the-last-dinner meal-to-cook

    ;guests store meal they had and cooking skills of cook
    let my-cooking-skills [cooking-skills] of self

    ask my-dinner-guests [ ;cook asks his guests to set last meal to the meal he cooked
      set my-last-dinner the-last-dinner
      set cooks-cooking-skills my-cooking-skills
    ]
  ]

  ask persons with [is-cook? = true and bought? = false] [
     ;if debug? [
   show "I did not buy anything, haha!"
    ;]
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
        let my-meals-quality random-normal cooks-cooking-skills meal-quality-variance ;meal quality here is dependent of cooking skills of the cook: cooking skills +/- a hard-coded standard deviation
                                                                                      ;print (list who my-meals-quality is-cook?)
        ask my-dinner-guests [
          set last-meals-quality my-meals-quality
          ;print (list who last-meals-quality is-cook?)

          (ifelse last-meals-quality < 0.55 [ ;hard-coded value for a sufficient mark in The Netherlands, 5.5
            set last-meal-enjoyment? false ;technically not resetting but reinforcing as it is a boolean
          ] last-meals-quality >= 0.55 [
            set last-meal-enjoyment? true
          ] [
            ;if no meal evaluation took place
            show "I did not evaluate the meal I just had!"
          ])
        ]
      ]
    ]
  ]



end

to update-diet-preference

  ask persons with [openminded? = true] [

    ifelse last-meal-enjoyment? = true and my-last-dinner != "potatoes" [

      ;update table with meal enjoyments for each type of diet based on neophobia
      let current-meal-enjoyment table:get meal-enjoyment-table my-last-dinner
      let new-meal-enjoyment current-meal-enjoyment + ( ( last-meals-quality * (1 - neophobia) ) / 100 ) ;add a multiplication of last meal's quality and the neophobia, here a low neophobia leads to a larger increment in meal enjoyment
      if new-meal-enjoyment > 1 [set new-meal-enjoyment 1]
      table:put meal-enjoyment-table my-last-dinner new-meal-enjoyment
    ] [

      ifelse last-meal-enjoyment? = false and my-last-dinner != "potatoes" [
        ;update table with meal enjoyments for each type of diet based on neophobia
        let current-meal-enjoyment table:get meal-enjoyment-table my-last-dinner
        let new-meal-enjoyment current-meal-enjoyment - ( ( last-meals-quality * (1 - neophobia) ) / 100 ) ;add a multiplication of last meal's quality and the neophobia, here a low neophobia leads to a larger increment in meal enjoyment
        if new-meal-enjoyment <= 0 [set new-meal-enjoyment 0.001]
        table:put meal-enjoyment-table my-last-dinner new-meal-enjoyment
      ]
[
      ;if my-last-dinner = "potatoes"
      if debug?
      [show (word "We poor people in household "h-id " had to eat potatoes, grr at at time step " ticks)]

    ]

    ;update dietary preference, if necessary

    if debug? [
      show (word "My selected diet before updating is: " diet)
    ]

    let max-diet "none"
    let max-value 0

    ;check for each dietary preference if it has the highest value and choose the highest value as the max-value

    foreach diets-list [ diets ->
      let value table:get meal-enjoyment-table diets

      if value > max-value [
        set max-value value
        set max-diet diets
      ]
    ]



    set diet max-diet

        if debug? [
      show (word "My selected diet after updating is: " diet)
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
    let status-change delta-status * 0.01
    ;print (list who my-status my-cook status-of-my-cook)

    (ifelse my-status < status-of-my-cook or my-status = status-of-my-cook [ ;if my cook has a higher status than myself or the same status, I will always show gratitude for the meal, even if I don't like it
      ask my-cook [
        ;print "my status is being increased because my dinner guests liked what I cooked for them"
        set status min (list 1 (status + status-change))
      ]
      ]

      my-status > status-of-my-cook and last-meal-enjoyment? = true [
        ask my-cook [
          ;print "my status is being increased because my dinner guests liked what I cooked for them"
          set status min (list 1 (status + status-change))
        ]
      ]

      my-status > status-of-my-cook and last-meal-enjoyment? = false [
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
      let status-change delta-status * 0.01

      (ifelse last-meal-enjoyment? = true [
        set status (status + status-change)
        ]

        last-meal-enjoyment? = false and cooks-status > my-status [
          ;print "my status is being reduced because I did not like the meal"
          set status (status - status-change)
        ]

        last-meal-enjoyment? = false and (cooks-status < my-status or cooks-status = my-status) [ ;when the cooks status is lower or similar to that of the guests and the experience is negative, the cook will still give status
                                                                                                      ;print "my status is being increased because I am considered important by the cook"
          set status (status + status-change)
        ]

        ;if no last-meal-enjoyment
        [print (list who "I do not have an opinion about the last meal I had!")]

      )

    ]
  ]


end

to normalize-status

  ;attempt to adjust for the strong binary outcome of status distribution in the population, as status is artifically capped at 0 and 1.

  let status-list []
  let max-status "none"
  let min-status "none"
  let range-status "none"

  ask persons [
    set status-list lput ( [status] of self ) status-list
  ]

  set max-status max status-list
  set min-status min status-list
  set range-status max-status - min-status
  let lowest-status 0.0000000000000001
  let highest-status 0.9999999999999999

  ask persons [
    set status (lowest-status + ((status - min-status) * (highest-status - lowest-status) ) / range-status )
  ]

  if debug? [
  print status-list
  print max-status
  print min-status
  print range-status
  ]


end

;;; END OF MEAL EVALUATION ;;;

;;; FOOD OUTLETS CHECK SALES AND UPDATE STOCKS ;;;

to check-sales-tables ;food-outlet procedure

  ;determine sales
  ask food-outlets [

  ifelse supply-demand = "static-restocking" or supply-demand = "dynamic-restocking" [

      let total-sales 0

      foreach diets-list [ diets ->
        let sales-product table:get sales-table diets
        if debug? [
        show (word "check-sales-table This is our sales of: " diets " : " sales-product )
        ]
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


      ;if the supermarket has had no sales for several weeks, it will be registered in a global reporter
      (ifelse no-sales-count <= 180 [ ;hard-coded as 6 months of no sales
                                      ;do nothing - stay in business
        ]

        no-sales-count > 180 [ ;hard-coded as 6 months of no sales

          show ("I have not sold anything for six months")
          set total-no-sales-count total-no-sales-count + 1
          set no-sales-count 0

        ]


        ;if the food outlet cannot decide if it sold enough products to stay in business
        [print (list who "I cannot decide if I sold enough to stay in business")]
      )

      ;store the sales per day per protein source in a list for use in the restocking procedure

            if debug? [
      show (word "Our diet-sublists-table before adding new sales:" diet-sublists-table)
      ]

      ;store each sales-list in the diet-sublists-table for use in the restocking procedure
      foreach diets-list [ diets ->
        let today-sales table:get sales-table diets ;sales of today
        if debug? [
          show (word "This is today's sales of: " diets " " today-sales)
        ]

        let forever-sales-list table:get diet-sublists-table diets ;sales of previous days
        if debug? [
          show (word "This is total forever saleslist  of: " diets " " forever-sales-list)
        ]

        ;let forever-sales first forever-sales-list show word "This is total forever sales of: " diets " " forever-sales

        let nr-complaints table:get complaints-from-customers diets ;complaints of today, should be added to today-sales

        let total-current-sales today-sales + nr-complaints

        table:put diet-sublists-table diets (lput total-current-sales forever-sales-list )]

       if debug? [
       show (word "Our diet-sublists-table after adding new sales:" diet-sublists-table)
      ]

    ]


    ;if supply-demand = "infinite stock" food outlets do not need to check their sales
    [
      if debug? [
      show "People eat from heaven, no need to check my sales"
      ]
    ]



  ]


end

to check-restocking-tables

  ask food-outlets [

    if debug? [
      show (word "Supply-demand: " supply-demand " Stock-table at the start of procedure: " stock-table)
    ]

    if supply-demand = "infinite-stock" [
      ; No restocking required
      if debug? [
        show (word "Supply-demand: " supply-demand " | Stock-table at the end of procedure : " stock-table)
      ]
    ]

    if supply-demand = "static-restocking" [
      ; Reset stock-table to match initial-stock-table
      foreach diets-list [ diets ->
        table:put stock-table diets table:get initial-stock-table diets
      ]
      if debug? [
        show (word "Supply-demand: " supply-demand " Stock-table at the end: " stock-table)
      ]
    ]

    if supply-demand = "dynamic-restocking" [

      ;first check if stocks have become negative
      foreach diets-list [ diets ->
        let check-stock table:get stock-table diets
        if check-stock < 0 and ticks > 150 [

          show (word "check-restock-tables We have gone surreal, our stock of " diets " has become negative: " check-stock " at tick " ticks)
            set error? true
          ]
        ]


        ;test if it is restocking day
      let restocking-time ticks mod restocking-frequency

      if restocking-time != 0 and ticks != 0 [

        ;check if stocks have reached 0 already, if so, add to global reporter

        foreach diets-list [ diets ->
          let current-stock (table:get stock-table diets)
          ifelse current-stock = 0 [
            if debug? [
              show (word "Disaster! At time step " ticks " we ran out of :" diets " with only " current-stock " left.")
            ]


            let outlet-who who
            let empty-shelves-list table:get food-outlets-empty-shelves-table outlet-who
            let sold-out-protein diets
            table:put food-outlets-empty-shelves-table  outlet-who (lput sold-out-protein  empty-shelves-list)
             if debug? [
            show (word "Table AFTER adding another empty shelve: " food-outlets-empty-shelves-table )
            ]


          ]
          ;if current-stock > 0
              [
                ;do nothing, everything is okay
              ]
          ]


          if debug? [
            show (word "Our stock table: " stock-table)
          ]



        ;do nothing, it is not restocking day
      ]

      if restocking-time = 0 and ticks != 0 [
        ;it is restocking day!
        if debug? [
        show (word "It is restocking day! at " ticks)
        ]


        ;retrieve the sales-lists from diet-sublists-table and update the stock accordingly

        if debug? [
          show (word "stock table before updating " stock-table)
        ]

        foreach diets-list [ diets ->
          ;first retrieve the sales from each protein source
          let current-sales-list table:get diet-sublists-table diets
          let restocking-purpose-sales-list sublist current-sales-list (length current-sales-list - restocking-frequency) length current-sales-list
          if debug? [
            show (word "current-sales-list for: " diets " " current-sales-list " restocking-purpose-sales-list " restocking-purpose-sales-list)
          ]

          ;take the mean sales since the last restocking day
          let mean-sublist mean restocking-purpose-sales-list
          if debug? [
            show (word "our mean sales of: " diets " " mean-sublist " at tick " ticks)
          ]

          ;update the stock using the mean
          let current-stock table:get stock-table diets
          if debug? [
            show (word "check-restocking-table This is the current stock of " diets  " : " current-stock)
          ]

          ;update the stocks according to Q = S - I. Q = quantity to be ordered, S = inventory level up to which is ordered based on demand, I = inventory left
          ;table:put stock-table diets round ( ( mean-sublist * restocking-frequency ) + (mean-sublist * restocking-frequency * 0.1) - current-stock ) ;
          table:put stock-table diets round  ( current-stock + ( ( mean-sublist + (mean-sublist * 0.1) ) * restocking-frequency ) - current-stock )

        ]

        ;if one of the interventions to change the animal or protein stocks has been activated, apply these changes immediately after the restocking, so the intervention is applied to the most recent stocks

        ;ifelse intervention-implementation = "sudden"
        ;[
          ;intervention only occurs once at the first restocking day after 2 years
          ifelse change-plant-protein? = true and ticks > 730 and ticks < 730 + restocking-frequency [
            change-plant-protein
            show (word "We are changing plant protein stock at " ticks)
          ]

          ;if ticks != 730, do nothing
          [
            ;we are not changing the assortment
          ]

          ifelse change-animal-protein? = true and ticks > 730 and ticks < 730 + restocking-frequency [
            show (word "We are changing animal protein stocks at " ticks)
            change-animal-protein
          ]
          ;if ticks != 730, we are not changing the assortment
          [
            ;do nothing
          ]
        ;]

        ;if intervention-implementation = "gradual"
        ;[
          ;intervention occurs at every restocking day after 2 years

          ifelse change-plant-protein? = true and ticks > 730 [
            change-plant-protein
            show (word "We are changing plant protein stock at " ticks)
          ]

          ;if ticks != 730, do nothing
          [
            ;we are not changing the assortment
          ]

          ifelse change-animal-protein? = true and ticks > 730 [
            show (word "We are changing animal protein stocks at " ticks)
            change-animal-protein
          ]
          ;if ticks != 730, we are not changing the assortment
          [
            ;do nothing
          ]
        ;]


        if debug? [
          show (word "stock table after updating " stock-table)
        ]

      ]

      if debug? [
        show (word "Supply-demand: " supply-demand " Stock-table at the end: " stock-table)
      ]
    ]
  ]

  if debug? [
    ;show (word "Empty shelves table: " empty-shelves-table)
  ]


  ;check empty shelves
  ;in case all outlets had an empty shelve, an empty shelve for that particular protein source should be added in the protein empty shelves table

  ;
  ;use diets-list for the 4 protein sources
  ;food-outlets-empty-shelves-table --> stores for each food outlet which protein source was sold out in this time step
  ;proteins-empty-shelves-table --> stores if one protein source was sold out in all food outlets this time step

  foreach diets-list [ diets ->
    let appears-in-all? true

    foreach table:keys food-outlets-empty-shelves-table [ outlet-who ->
      let sold-out-protein table:get food-outlets-empty-shelves-table outlet-who
      if debug? [
      print (word sold-out-protein outlet-who)
      ]
      if not member? diets sold-out-protein [
      set appears-in-all? false
      if debug? [
          print (word appears-in-all? diets outlet-who)
        ]
      ]

    ]

 if appears-in-all? [
   table:put proteins-empty-shelves-table diets 1
    ]
    if debug? [
    print (word "Proteins empty shelves table at " ticks "  " proteins-empty-shelves-table)
    ]

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

    foreach diets-list [ diets ->
      ; check if current food outlet sells this product
      ifelse member? diets product-selection [
      let sales-product table:get sales-table diets

        ;add the sales of the product to the global report-sales table
      let current-sales (table:get report-sales-table diets)
      table:put report-sales-table diets (current-sales + sales-product)
    ] [
        ; If the product is not offered, do nothing
        ; Keep the current sales unchanged
      ]
    ]


    let sales-potatoes table:get potatoes-table "potatoes"
    let current-sales-potatoes table:get potatoes-table "potatoes"
    table:put report-potatoes-table "potatoes" (current-sales-potatoes + sales-potatoes)
  ]


end

to prepare-stock-reporter

  ask food-outlets [

    foreach diets-list [ diets ->
      ; Check if the current food outlet offers this product
      ifelse member? diets product-selection [
        ; If the product is offered, get its stock
        if debug? [
        show (word "I offer " product-selection " so I can add stock of: " diets)
        ]
        let stock-product table:get stock-table diets

        ; Add the stock of the product to the global report-stock-table
        let current-total (table:get report-stock-table diets)
        table:put report-stock-table diets (current-total + stock-product)
      ] [
        ; If the product is not offered, do nothing
        ; Keep the current total unchanged
      ]
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


  ;set table with difference in stocks for the current tick compared to the previous tick
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

to prepare-relative-change-sales-reporter


  ;set table with difference in sales for the current tick compared to the previous tick
  foreach diets-list [diets ->
    let current-sales table:get report-sales-table diets
    let previous-sales table:get report-saved-sales-table diets
    let delta-sales (current-sales - previous-sales)

    (ifelse previous-sales = 0 and delta-sales != 0 [
      table:put report-delta-sales-table diets 1
      ]
      delta-sales = 0 [
        table:put report-delta-sales-table diets 0 ;no change in sales
      ]
      previous-sales != 0 and delta-sales != 0 [
        let relative-change-sales ((delta-sales / previous-sales) * 1 )
        table:put report-delta-sales-table diets relative-change-sales
      ]
      ;if something goes wrong
      [show "We cannot calculate the relative change in sales"]
    )
  ]

  ;set table that remembers the dietary preferences at the current tick for the next tick
  foreach diets-list [diets ->
    let count-saved-sales table:get report-sales-table diets
    table:put report-saved-sales-table diets count-saved-sales
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

;; percentage eating out ;;

to-report percentage-eating-in
  let people-eating-in persons with [at-home? = true]
  let fraction-eating-in count people-eating-in / count persons
  report fraction-eating-in
end

to-report percentage-enjoying-meal
  let people-positive-enjoyment persons with [last-meal-enjoyment? = true]
  let fraction-enjoying-meal count people-positive-enjoyment / count persons
  report fraction-enjoying-meal
end

;; sales ;;

to-report meat-sales
  let meat-sold table:get report-sales-table "meat"
  report meat-sold
end

to-report fish-sales
  let fish-sold table:get report-sales-table "fish"
  report fish-sold
end

to-report vegetarian-sales
  let vegetarian-sold table:get report-sales-table "vegetarian"
  report vegetarian-sold
end

to-report vegan-sales
  let vegan-sold table:get report-sales-table "vegan"
  report vegan-sold
end

to-report potatoes-sales
  let potatoes-sold table:get report-potatoes-table "potatoes"
  report potatoes-sold
end

to-report bad-sales
  report total-no-sales-count
end

;empty shelves

;reporting empty shelve in each supermarket
;to-report empty-meat-shelve
;  let empty-meat table:get empty-shelves-table "meat"
;  report empty-meat
;end
;
;to-report empty-fish-shelve
;  let empty-fish table:get empty-shelves-table "fish"
;  report empty-fish
;end
;
;to-report empty-vegetarian-shelve
;  let empty-vegetarian table:get empty-shelves-table "vegetarian"
;  report empty-vegetarian
;end
;
;to-report empty-vegan-shelve
;  let empty-vegan table:get empty-shelves-table "vegan"
;  report empty-vegan
;end

;reporting all food outlets running out of a protein source

to-report empty-meat-shelve
  let empty-meat table:get proteins-empty-shelves-table "meat"
  report empty-meat
end

to-report empty-fish-shelve
  let empty-fish table:get proteins-empty-shelves-table "fish"
  report empty-fish
end

to-report empty-vegetarian-shelve
  let empty-vegetarian table:get proteins-empty-shelves-table "vegetarian"
  report empty-vegetarian
end

to-report empty-vegan-shelve
  let empty-vegan table:get proteins-empty-shelves-table "vegan"
  report empty-vegan
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

;; relative sales changes ;;

to-report relative-change-meat-sales
  let relative-change table:get report-delta-sales-table "meat"
  report relative-change
end

to-report relative-change-fish-sales
  let relative-change table:get report-delta-sales-table "fish"
  report relative-change
end

to-report relative-change-vegetarian-sales
  let relative-change table:get report-delta-sales-table "vegetarian"
  report relative-change
end

to-report relative-change-vegan-sales
  let relative-change table:get report-delta-sales-table "vegan"
  report relative-change
end



;; frequency reporter ;;

to-report frequency [x freq-list]
  report reduce [ [occurrence-count next-item] -> ifelse-value (next-item = x) [occurrence-count + 1] [occurrence-count] ] (fput 0 freq-list)
end
@#$#@#$#@
GRAPHICS-WINDOW
876
165
1494
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
12
98
185
131
initial-nr-households
initial-nr-households
15
1425
125.0
15
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
8
637
163
697
current-seed
-2.0371782E8
1
0
Number

SWITCH
171
638
284
671
fixed-seed?
fixed-seed?
1
1
-1000

PLOT
416
163
643
310
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
1088
15
1291
163
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
8
179
172
224
meal-selection
meal-selection
"status-based" "majority" "random"
0

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
1292
16
1491
159
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
9
138
182
171
nr-friends
nr-friends
0
15
3.0
1
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
14
243
212
269
SCENARIOS & INTERVENTIONS
10
0.0
1

TEXTBOX
15
617
152
635
RUN CONTROLS
10
0.0
1

SLIDER
194
97
366
130
initial-nr-food-outlets
initial-nr-food-outlets
1
11
7.0
1
1
NIL
HORIZONTAL

SLIDER
193
184
368
217
food-outlet-service-area
food-outlet-service-area
20
60
40.0
5
1
NIL
HORIZONTAL

PLOT
413
471
640
615
total stocks in food outlet
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

PLOT
645
163
873
312
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
291
639
394
672
error?
error?
1
1
-1000

PLOT
646
15
874
163
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
645
469
873
617
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

CHOOSER
8
541
174
586
influencers
influencers
"random" "high-status" "low-status"
1

SLIDER
5
503
177
536
p-influencers
p-influencers
0
1
0.1
0.01
1
NIL
HORIZONTAL

CHOOSER
184
541
355
586
influencers-diet
influencers-diet
"meat" "fish" "vegetarian" "vegan"
2

SWITCH
9
464
135
497
change-diets?
change-diets?
0
1
-1000

SWITCH
8
360
181
393
change-plant-protein?
change-plant-protein?
1
1
-1000

SLIDER
9
397
182
430
p-change-plant-protein
p-change-plant-protein
-1
1
0.75
0.01
1
NIL
HORIZONTAL

SWITCH
185
359
363
392
change-animal-protein?
change-animal-protein?
1
1
-1000

SLIDER
184
397
362
430
p-change-animal-protein
p-change-animal-protein
-0.25
0.25
0.039
0.001
1
NIL
HORIZONTAL

PLOT
413
778
639
928
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
878
18
1084
160
Population (black) vs Stocks (blue)
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
"default" 1.0 0 -13791810 true "" "plot total-stocks"
"pen-1" 1.0 0 -16777216 true "" "plot count persons"

TEXTBOX
12
336
162
354
Adjust product range at t = 730
10
0.0
1

TEXTBOX
11
442
161
460
Adjust diets at t = 730
10
0.0
1

PLOT
413
316
639
466
total sales
NIL
NIL
0.0
10.0
-0.5
0.5
true
false
"" ""
PENS
"default" 1.0 0 -6459832 true "" "plot meat-sales"
"pen-1" 1.0 0 -2064490 true "" "plot fish-sales"
"pen-2" 1.0 0 -1184463 true "" "plot vegetarian-sales"
"pen-3" 1.0 0 -13840069 true "" "plot vegan-sales"
"pen-4" 1.0 0 -14730904 true "" "plot potatoes-sales"

SLIDER
195
139
367
172
restocking-frequency
restocking-frequency
1
12
8.0
1
1
NIL
HORIZONTAL

CHOOSER
11
269
161
314
supply-demand
supply-demand
"infinite-stock" "static-restocking" "dynamic-restocking"
2

SWITCH
171
677
284
710
debug?
debug?
1
1
-1000

PLOT
412
620
638
772
empty shelves counter
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
"pen-1" 1.0 0 -8431303 true "" "plot empty-meat-shelve"
"default" 1.0 0 -2064490 true "" "plot empty-fish-shelve"
"pen-2" 1.0 0 -4079321 true "" "plot empty-vegetarian-shelve"
"pen-3" 1.0 0 -13840069 true "" "plot empty-vegan-shelve"

PLOT
647
316
870
466
relative change in sales
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
"meat" 1.0 0 -8431303 true "" "plot relative-change-meat-sales"
"fish" 1.0 0 -2064490 true "" "plot relative-change-fish-sales"
"pen-2" 1.0 0 -4079321 true "" "plot relative-change-vegetarian-sales"
"pen-3" 1.0 0 -13840069 true "" "plot relative-change-vegan-sales"

SLIDER
183
502
355
535
status-tail
status-tail
0
0.5
0.25
0.01
1
NIL
HORIZONTAL

PLOT
646
623
873
773
Eating in (black) .. Enjoying meal (blue)
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot percentage-eating-in"
"pen-1" 1.0 0 -13791810 true "" "plot percentage-enjoying-meal"

SLIDER
1504
117
1677
150
ofat-cooking-skills
ofat-cooking-skills
0
1
0.5
0.1
1
NIL
HORIZONTAL

SLIDER
1505
77
1677
110
ofat-status
ofat-status
0
1
0.5
0.1
1
NIL
HORIZONTAL

SLIDER
1506
39
1678
72
ofat-neophobia
ofat-neophobia
0
1
0.5
0.1
1
NIL
HORIZONTAL

MONITOR
186
444
269
489
animal-share
animal-share
0
1
11

SLIDER
187
269
359
302
intervention-duration
intervention-duration
1
730
180.0
1
1
NIL
HORIZONTAL

MONITOR
279
443
354
488
plant-share
plant-share
0
1
11

MONITOR
229
310
335
355
monitor-duration
monitor-duration
0
1
11

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
  <experiment name="dynamic_status_based_change_diets_lowstatus" repetitions="20" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count persons with [meal-to-cook = "meat"]</metric>
    <metric>count persons with [meal-to-cook = "fish"]</metric>
    <metric>count persons with [meal-to-cook = "vegetarian"]</metric>
    <metric>count persons with [meal-to-cook = "vegan"]</metric>
    <metric>count persons with [diet = "meat"]</metric>
    <metric>count persons with [diet = "fish"]</metric>
    <metric>count persons with [diet = "vegetarian"]</metric>
    <metric>count persons with [diet = "vegan"]</metric>
    <metric>meat-stock</metric>
    <metric>fish-stock</metric>
    <metric>vegetarian-stock</metric>
    <metric>vegan-stock</metric>
    <metric>meat-sales</metric>
    <metric>fish-sales</metric>
    <metric>vegetarian-sales</metric>
    <metric>vegan-sales</metric>
    <metric>status-distribution</metric>
    <metric>current-seed</metric>
    <runMetricsCondition>ticks mod 365 = 0</runMetricsCondition>
    <enumeratedValueSet variable="nr-friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="supply-demand">
      <value value="&quot;dynamic-restocking&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-outlet-service-area">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="restocking-frequency">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fixed-seed?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-nr-households">
      <value value="250"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="error?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="meal-selection">
      <value value="&quot;status-based&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debug?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-nr-food-outlets">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="intervention-duration">
      <value value="30"/>
      <value value="360"/>
      <value value="1825"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="influencers-diet">
      <value value="&quot;vegan&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="influencers">
      <value value="&quot;low-status&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="change-diets?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-influencers">
      <value value="0.1"/>
      <value value="0.4"/>
      <value value="0.6"/>
      <value value="0.9"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="dynamic_status_based_change_diets_highstatus" repetitions="20" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count persons with [meal-to-cook = "meat"]</metric>
    <metric>count persons with [meal-to-cook = "fish"]</metric>
    <metric>count persons with [meal-to-cook = "vegetarian"]</metric>
    <metric>count persons with [meal-to-cook = "vegan"]</metric>
    <metric>count persons with [diet = "meat"]</metric>
    <metric>count persons with [diet = "fish"]</metric>
    <metric>count persons with [diet = "vegetarian"]</metric>
    <metric>count persons with [diet = "vegan"]</metric>
    <metric>meat-stock</metric>
    <metric>fish-stock</metric>
    <metric>vegetarian-stock</metric>
    <metric>vegan-stock</metric>
    <metric>meat-sales</metric>
    <metric>fish-sales</metric>
    <metric>vegetarian-sales</metric>
    <metric>vegan-sales</metric>
    <metric>status-distribution</metric>
    <metric>current-seed</metric>
    <runMetricsCondition>ticks mod 365 = 0</runMetricsCondition>
    <enumeratedValueSet variable="nr-friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="supply-demand">
      <value value="&quot;dynamic-restocking&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-outlet-service-area">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="restocking-frequency">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fixed-seed?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-nr-households">
      <value value="250"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="error?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="meal-selection">
      <value value="&quot;status-based&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debug?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-nr-food-outlets">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="intervention-duration">
      <value value="30"/>
      <value value="360"/>
      <value value="1825"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="influencers-diet">
      <value value="&quot;vegan&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="influencers">
      <value value="&quot;high-status&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="change-diets?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-influencers">
      <value value="0.1"/>
      <value value="0.4"/>
      <value value="0.6"/>
      <value value="0.9"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="dynamic_status_based_change_diets_random" repetitions="20" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count persons with [meal-to-cook = "meat"]</metric>
    <metric>count persons with [meal-to-cook = "fish"]</metric>
    <metric>count persons with [meal-to-cook = "vegetarian"]</metric>
    <metric>count persons with [meal-to-cook = "vegan"]</metric>
    <metric>count persons with [diet = "meat"]</metric>
    <metric>count persons with [diet = "fish"]</metric>
    <metric>count persons with [diet = "vegetarian"]</metric>
    <metric>count persons with [diet = "vegan"]</metric>
    <metric>meat-stock</metric>
    <metric>fish-stock</metric>
    <metric>vegetarian-stock</metric>
    <metric>vegan-stock</metric>
    <metric>meat-sales</metric>
    <metric>fish-sales</metric>
    <metric>vegetarian-sales</metric>
    <metric>vegan-sales</metric>
    <metric>status-distribution</metric>
    <metric>current-seed</metric>
    <runMetricsCondition>ticks mod 365 = 0</runMetricsCondition>
    <enumeratedValueSet variable="nr-friends">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="supply-demand">
      <value value="&quot;dynamic-restocking&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-outlet-service-area">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="restocking-frequency">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fixed-seed?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-nr-households">
      <value value="250"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="error?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="meal-selection">
      <value value="&quot;status-based&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debug?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-nr-food-outlets">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="intervention-duration">
      <value value="30"/>
      <value value="360"/>
      <value value="1825"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="influencers-diet">
      <value value="&quot;vegan&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="influencers">
      <value value="&quot;random&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="change-diets?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-influencers">
      <value value="0.1"/>
      <value value="0.4"/>
      <value value="0.6"/>
      <value value="0.9"/>
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
