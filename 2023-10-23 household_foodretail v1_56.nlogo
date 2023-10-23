;; version 1.0 ;;

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

]


persons-own [
  ;age
  diet
  is-cook?
  cooking-skills
  cs-meat
  cs-fish
  cs-veget
  cs-vegan
  cooks-cooking-skills
  h-id
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
  uncertainty-avoidance
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
  product-selection
  sales-table
  sales
  initial-stock-table
  stock-table
  no-sales-count
  business-orientation ;0 = not considering sustainability at all, 2 = considering sustainability in assortment a lot
  opening-day
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

  set diet-list (list (list "meat" p-me ) (list  "fish" p-fi ) (list "vegetarian" p-vt ) (list "vegan" p-vn ))
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

  set income-level-price-table table:make

  table:put income-level-price-table "low" 2
  table:put income-level-price-table "middle" 4
  table:put income-level-price-table "high" 6


end

to setup-households
  create-households initial-nr-households
  ask households [
    move-to one-of patches with [not any? households-here]
    set shape "house"
    set color 37
    set id id-households + 1
    set id-households id-households + 1 ;each households updates the global variable id-households
                                        ;create household with members
    set income-level first rnd:weighted-one-of-list income-levels [ [p] -> last p ]
    let new-family random-normal mean-family-size sd-family-size
    let new-family-abs abs new-family
    hatch-persons new-family-abs + 1
    set empty-house? false
    set meal-cooked? false
    set diet-diversity 0
    set vip-preference "none"

  ]

  ;check: no more than one house per patch
  ask patches with [count households-here > 1] [
    error "more than one house here!"
  ]
end

to setup-persons
  ask persons [
    ;set age random-normal 41 25 ; mean and sd are chosen based on Dutch demographic data
    set shape "person"
    set color pink
    set diet first rnd:weighted-one-of-list diet-list [ [p] -> last p ]
    set is-cook? false
    set meal-to-cook "none"
    set cooking-skills random-float 1
    set status random-float 1
    set uncertainty-avoidance random-float 1
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
    set cs-meat random-float max-cs-meat
    set cs-fish random-float max-cs-fish
    set cs-veget random-float max-cs-veget
    set cs-vegan random-float max-cs-vegan
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
    ask persons [
      let potential-friends other persons with [h-id != [h-id] of myself]
      let nr-friendships random nr-friends ;people will create 0 or 1 friends
      repeat nr-friendships [create-friendship-with one-of potential-friends [set color 9.9]]
    ]
  ]
  ;friendships? = false
  [
    ;do nothing
  ]
end


to setup-food-outlets
  create-food-outlets initial-nr-food-outlets
  ask food-outlets [
    move-to one-of patches with [not any? turtles-here]
    set shape "square 2"
    set color 25
    set size 1
    set business-orientation random-float 2
    set opening-day 0
    ;food-outlet counts number of persons in certain radius
    set potential-costumers count persons in-radius food-outlet-service-area

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
                                                                                                      ;show product-selection


    ;food outlets determine for each product in their product-selection, how much of this product is in stock

    set initial-stock-table table:make
    set sales-table table:make
    set stock-table table:make



    let sustainable-foods []

    (ifelse shops-sustainable? = false [

      foreach diets-list [ diets ->
        table:put initial-stock-table diets ifelse-value (member? diets product-selection) [
          round ( (potential-costumers / nr-products) * stock-multiplication-factor )
        ] [
          0
        ]

        ;show (word "My initial stock of " diets " is " (table:get initial-stock-table diets))
        table:put sales-table diets 0
        table:put stock-table diets table:get initial-stock-table diets
        ;show stock-table
      ]

      ]


      shops-sustainable? = true [
        ;based on their business orientation, food outlets will adjust their 'standard' assortment

        foreach diets-list [ diets ->
          table:put initial-stock-table diets ifelse-value (member? diets product-selection) [
            round (potential-costumers / nr-products)
          ] [
            0
          ]

          ;show (word "My initial stock of " diets " is " (table:get initial-stock-table diets))
          table:put sales-table diets 0
          table:put stock-table diets table:get initial-stock-table diets
          ;show stock-table
        ]

        set sustainable-foods (list "vegetarian" "vegan")

        foreach sustainable-foods [ food-item ->

          let assortment-change ( (1 / length sustainable-foods) * potential-costumers * business-orientation )
          table:put initial-stock-table food-item round assortment-change

          table:put stock-table food-item table:get initial-stock-table food-item
          ;show stock-table

        ]
      ]
      ;if something goes wrong
      [show "I cannot decide if I have to adjust my stock based on my business orientation"]
    )


    set no-sales-count 0
    set label product-selection

  ]

  ask persons [
    set sorted-food-outlets sort-on [distance myself] food-outlets
    set supermarket-changes length sorted-food-outlets
  ]

end

;to setup-foods
;
;end

;;;;;;;;;
;; RUN ;;
;;;;;;;;;

to go

  if ticks = 365 * 10 or error? = true [stop]

  closure-of-tick
  select-group-and-cook
  select-meal
  go-to-supermarket
  ;check-groceries
  cooking
  set-meal-evaluation
  evaluate-meal
  check-sales
  update-stock
  visualization
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
    set meal-to-cook "none"
    set is-cook? false
    set my-dinner-guests "nobody"
    set my-cook "nobody"
    set cooks-cooking-skills "none"
    set last-meals-quality "none"
    set last-meal-enjoyment "none"
    set bought? false

    let dinner-friends friendship-neighbors
    let dinner-members family-membership-neighbors
    let network-members (turtle-set dinner-friends dinner-members self)
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

        (ifelse dynamic-cs? = true [
          set cooking-skills min (list 1 (cooking-skills + 0.01))
          ]
          dynamic-cs? = false [
            ;do nothing - the cook does not improve his cooking
          ]
          ;if dynamic-cs? is not set for some reason
          [print (list who "I don't know what to do with cooking skills")]
        )






        ask my-dinner-guests [
          set my-cook todays-cook ;setting todays cook for all dinner-group members
                                  ;print (list who my-cook) ;they all print themselves as my-cook
        ]
      ]
    ]

    ;; procedure to select dinner and guests if friendships are turned on ;all household members who are todays-cook and who have friends can invite friends over for dinner
    [
      let members-at-home count members with [at-home? = true]
      ifelse members-at-home = 0  [
        set empty-house? true
        ;do not cook a meal in this household today, because no one is home
      ]

      ;if at least 1 member is at home, cook a meal in this household
      [
        set meal-cooked? true
        let todays-cook one-of members with [is-cook? = false and at-home? = true] ;select cook that is at home
        let todays-dinner-guests members

        ask todays-cook [

          set is-cook? true

          (ifelse dynamic-cs? = true [
            set cooking-skills min (list 1 (cooking-skills + 0.01))
            ]
            dynamic-cs? = false [
              ;do nothing - the cook does not improve his cooking
            ]
            ;if dynamic-cs? is not set for some reason
            [print (list who "I don't know what to do with cooking skills")]
          )

          let nr-dinner-friends count friendship-neighbors with [at-home? = true]


          ;;if the cook has no friends
          ifelse nr-dinner-friends = 0 [
            set my-dinner-guests todays-dinner-guests ;do not invite friends because I do not have any
          ]

          ;;if the cook does have friends
          ;nr-dinner friends != 0
          [

            let dinner-friends friendship-neighbors with [at-home? = true and is-cook? = false] ;only invite friends who are still at home and do not have to cook for their own household
            ask dinner-friends [
              set at-home? false
              move-to patch-here
            ]

            let dinner-members family-membership-neighbors with [at-home? = true]
            set my-dinner-guests (turtle-set dinner-members dinner-friends self)

          ]

          ask my-dinner-guests [
            set my-cook todays-cook ;setting todays cook for all dinner-group members

          ]

        ]
      ]


    ]

  ]

  ask persons with [is-cook? = true] [
    let nr-of-dinner-guests count my-dinner-guests
    if nr-of-dinner-guests = 0 [
      error "I have an empty guest list!"
    ]
  ]
end

to select-meal ;person procedure

  ;every meal selection procedure ends with a set meal-to-cook for the cook

  ask persons with [is-cook? = true]  [

    (ifelse meal-selection = "status-based" [
      status-based-meal-selection
      ]

      meal-selection = "skills-based" [
        skills-based-meal-selection
      ]

      meal-selection = "data-based" [
        data-based-meal-selection
      ]

      meal-selection = "majority" [
        majority-based-meal-selection
      ]

      meal-selection = "random" [
        random-meal-selection
      ]

      meal-selection = "norm-random" [
        norm-random-meal-selection
      ]

      meal-selection = "collectivism" [
        collectivism-based-meal-selection
      ]

      meal-selection = "uncertainty-avoidance" [
        uncertainty-avoidance-based-meal-selection
      ]

      meal-selection = "cook-individualism" [
        cook-individualism-based-meal-selection
      ]

      [
        ;if no meal-selection option has been selected
        print(list who "We do not know how to select our meal!")
      ]

    )

  ]

end

to random-meal-selection

  ;;procedure to select meal randomly

  let chosen-meal one-of diets-list ;choose random item from the list with diets
  set meal-to-cook chosen-meal   ;cook decides what type of meal to prepare

end

to norm-random-meal-selection

  ;;procedure to select meal randomly from the dietary preferences of the dinner guests, so reflecting somewhat the practice of a household

  let dinner-list [ (list who diet ) ] of my-dinner-guests
  let chosen-meal item 1 (first dinner-list) ;choose first diet on the list, so the second item in the first list; a random choice from the dietary preferences in the household
  set meal-to-cook chosen-meal   ;cook decides what type of meal to prepare
  set my-last-dinner chosen-meal

end

to data-based-meal-selection

  ;;procedure to select meal based on data, converted to a chance of choosing a particular type of protein: meat, fish, dairy + eggs, vegetable protein

  let meal-list (list (list "meat" 0.9 ) (list  "fish" 0.3 ) (list "vegetarian" 0.15 ) (list "vegan" 0.05 ))
  let chosen-meal first rnd:weighted-one-of-list meal-list [ [p] -> last p ]

  set meal-to-cook chosen-meal   ;cook decides what type of meal to prepare

end

to majority-based-meal-selection

  ;;procedure to select meal democratically

  let dinner-list-majority [ (list diet) ] of my-dinner-guests
  let freq-list map [ i -> frequency I dinner-list-majority] dinner-list-majority ;creates a list with for each diet on dinner-list-majority how frequent it appears in dinner-list-majority
  let dinner-freq-list table:from-list (map list freq-list dinner-list-majority) ;creates a table with the frequency for each diet on the dinner-list majority
  let count-majority-choice max freq-list ;select the highest count
  let majority-meal-list table:get dinner-freq-list count-majority-choice ;use highest count to select the diet with this highest count
  let majority-meal first majority-meal-list ;unpack diet / meal from list

  set meal-to-cook majority-meal   ;cook decides what type of meal to prepare

end

to status-based-meal-selection

  ;;procedure to select status-based a meal
  ask persons with [is-cook? = true and meal-to-cook = "none"] [

    let vip-guest max-one-of my-dinner-guests [status] ;choose guest with highest status; this could in this model version also be himself
    let vip-meal [diet] of vip-guest
    ;show (list vip-meal)
    ;show (list vip-meal meal-to-cook)
    set meal-to-cook vip-meal   ;cook has decided to cook meal preference of vip-guest
                                ;show (list meal-to-cook)                            ;show meal-to-cook
  ]

end

to collectivism-based-meal-selection


  ;;procedure to select meal based on the cultural dimension of individualism - collectivism - this procedure expands the majority-select-meal procedure

  ;determine majority meal
  let dinner-list-majority [ (list diet) ] of my-dinner-guests
  let freq-list map [ i -> frequency I dinner-list-majority] dinner-list-majority ;creates a list with for each diet on dinner-list-majority how frequent it appears in dinner-list-majority
  let dinner-freq-list table:from-list (map list freq-list dinner-list-majority) ;creates a table with the frequency for each diet on the dinner-list majority
  let count-majority-choice max freq-list ;select the highest count
  let majority-meal-list table:get dinner-freq-list count-majority-choice ;use highest count to select the diet with this highest count
  let majority-meal first majority-meal-list ;unpack diet / meal from list

  ;determine minority meal
  let count-minority-choice min freq-list ;check the minority preference
  let minority-meal-list table:get dinner-freq-list count-minority-choice
  let minority-meal first minority-meal-list ;QUESTION: what if two minority meals are present in the household? When printing it always seems to be only one meal

  (ifelse majority-meal = minority-meal [ ;meaning only one meal was on the diet list, so no choice needs to be made
    set meal-to-cook majority-meal   ;cook decides what type of meal to prepare
    ]

    majority-meal != minority-meal [

      ;depending on cultural value of collectivism a minority meal will be cooked
      let a random-float 1

      (ifelse collectivism-dim < a [  ;if a is larger than c-dim, then collectivism wins and: individual opinions are not appreciated / catered to), everyone will eat what the majority eats. It is assumed only one meal will be cooked.
        set meal-to-cook majority-meal   ;cook prepares majority meal
        ]

        collectivism-dim >= a [
          set meal-to-cook minority-meal
        ]

        ;if no comparision between a and collectivism-dim is made
        [print (list who "We do not know our collectivism-value")]
      )

    ]

    ;no comparision betwee minority and majority meal is made
    [print (list who "We did not compare minority and majority meals")]

  )

end

to skills-based-meal-selection

  ;; procedure to select skills-based a meal

  let list-my-cs-names diets-list ;create list of diets / meals. Used diet names here instead of cs-[diet] to enable transfer to chosen-meal and plot of cooked meals
  let list-my-cs-values (list cs-meat cs-fish cs-veget cs-vegan) ;create list of cooking skills values
  let list-my-cs table:from-list (map list list-my-cs-values list-my-cs-names) ;create table with cooking skill for each diet / meal
  let my-best-cs max list-my-cs-values ;select the best cooking skill
  let chosen-meal table:get list-my-cs my-best-cs ;use the best cooking skill value to select the diet / meal

  set meal-to-cook chosen-meal   ;cook decides what type of meal to prepare


end

to uncertainty-avoidance-based-meal-selection

  let chosen-meal diet ;choose to prepare the cook's preference

  ;ask dinner guests if they would like to eat the proposed meal

  let agreement-table table:make

  ;create a list with the diets of my dinner guests

  let guest-diet-list []

  ask my-dinner-guests [
    set guest-diet-list lput diet guest-diet-list
  ]
  ;show guest-diet-list

  foreach guest-diet-list [ guests ->

    (ifelse diet = chosen-meal [
      table:put agreement-table guests "yes"
      ]
      diet != chosen-meal [

        let c random-float 1

        (ifelse uncertainty-avoidance <= c [
          table:put agreement-table guests "no"
          ]
          uncertainty-avoidance > c [
            table:put agreement-table guests "yes"
          ]
          ;if something goes wrong
          [show "I cannot decide if I want to try a new meal"]
        )
      ]

      ;if something goes wrong
      [show "I cannot decide what meal my cook has chosen"]
    )
  ]

  ;show agreement-table

  let agreement-list table:values agreement-table

  (ifelse member? "no" agreement-list [
   norm-random-meal-selection
    ]

    member? "yes" agreement-list [
      set meal-to-cook chosen-meal
    ]

    ;if something goes wrong
    [show "We could not decide what meal to cook"]
  )

end

to cook-individualism-based-meal-selection

  let b random-float 1

  (ifelse individualism <= b [ ;if individualism is smaller than b it means the cook is not too individualistic and will fall back to what is usually consumed within the family / dinner guest setting
    norm-random-meal-selection
  ]

  individualism > b [

  let try-out-diets-list []
  set try-out-diets-list filter [ s -> s != diet ] diets-list
  ;show (list diet try-out-diets-list)

  let chosen-meal one-of try-out-diets-list
  set meal-to-cook chosen-meal
  ]

  ;if something goes wrong
  [show "I was not able to determine if my individualism would decide our meal, or not"]
  )

end

to go-to-supermarket

  ask persons with [is-cook? = true and meal-to-cook != "none"] [

    (ifelse food-outlet-interaction? = true [

      while [bought? = false] [

        (ifelse my-supermarket = "none" and bought? = false and supermarket-changes != 0 [
          ;this procedures sets supermarket != "none"
          ;show "I am selecting supermarket"
          select-supermarket
          ]

          my-supermarket != "none" and bought? = false and supermarket-changes != 0 [
            ;this procedure can set bought? to true
            buy-groceries
          ]

          bought? = false and supermarket-changes = 0 [
            ;show ("I will try a new product despite my neophobia")
            ;this procedure sets bought? to true
            ;the agent has run out of supermarkets to search for his requested product because he was too neophobic to try an alternative product
            set sorted-food-outlets sort-on [distance myself] food-outlets
            set my-supermarket first sorted-food-outlets
            ;the agent will have to buy an alternative product because he cannot go home empty-handed
            buy-alternative-groceries
          ]

          ;if something goes wrong
          [show ("I cannot go to the supermarket")]
        )



      ]
      ]

      food-outlet-interaction? = false [
        ;it is assumed the requested product is infinitely available
      ]

      ;if the agent does not know if he should go to a supermarket or not
      [print (list who "I do not know if I should go to the supermarket")]
    )

  ]

end

to select-supermarket

  set my-supermarket first sorted-food-outlets
  set sorted-food-outlets but-first sorted-food-outlets

  ;show my-supermarket

end

to buy-groceries
  ;all the cooks go buy ingredients at the supermarket
  ;if the ingredient is available, they will prepare the selected meal
  ;if the ingredient is NOT available, they will select another meal in the procedure buy-alternative-groceries

  let requested-product meal-to-cook

  let available-products "none"

  ask my-supermarket [
    set available-products product-selection
  ]


  let available? member? meal-to-cook available-products ;check if food outlet sells required product
                                                         ; show (word "My meal is \"" meal-to-cook "\" options available are " available-products " and it is available? " available?)
  let nr-dinner-guests count my-dinner-guests ;determine for how many people I need to buy ingredients

  let stock-sufficient? "none"

  ;check if food outlet has required product still in stock for the quantity the cook needs
  ask my-supermarket [

    let current-stock (table:get stock-table requested-product)
    ;show (list requested-product current-stock)

    ;   show (word "I need " nr-dinner-guests " of " requested-product " and I have " table:get stock-table requested-product)

    (ifelse current-stock >= nr-dinner-guests [
      set stock-sufficient? true
      ]
      current-stock < nr-dinner-guests [
        set stock-sufficient? false
      ]
      ;if something goes wrong
      [show "I cannot determine if the shop has sufficient stock of my product"]
    )

  ]

  ;show (list nr-dinner-guests requested-product stock-sufficient?)


  let neophobic? uncertainty-avoidance > random-float 1 ;if uncertainty avoidance is larger than the result of the random float, the cook is neophobic
                                                        ;show (list "my neophobia is" neophobic?)



  (ifelse ( available? = false or stock-sufficient? = false ) and neophobic? = false [ ;if the supermarket does not offer their requested product but they are neophilic enough, they will buy an alternative product
    buy-alternative-groceries
    ]

    ( available? = false or stock-sufficient? = false ) and neophobic? = true [ ;if the supermarket does not offer their requested product but they are neophobic, they will try another supermarket
                                                                                ; go back to while loop
      set supermarket-changes supermarket-changes - 1
      ;show supermarket-changes
      ;show ("I am changing supermarket!")

      ifelse supermarket-changes != 0 [
        select-supermarket
      ]

      ;supermarket-changes = 0
      [
        set sorted-food-outlets sort-on [distance myself] food-outlets
        set my-supermarket first sorted-food-outlets
        buy-alternative-groceries
      ]

    ]


    available? = true [

;      ;check if the product is affordable
;
;      (ifelse price-influence? = true [
;        let my-household in-household-membership-from
;        let my-income-level [income-level] of household-membership
;
;      ]
;
;      price-influence? = false [
;        ;do nothing - just obtain the requested product
;      ]
;
;      ;if something goes wrong
;      [show "I cannot determine if I can afford this product"]
;      )

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

      ;the cook buys the product and adds his purchase to the sales of the food outlet
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

    ]

    ;if cook cannot determine if a product is available
    [print (list who "I cannot determine if the product I want to purchase is available")]
  )


  ;if bought? = true [
  ;    show (list my-supermarket meal-to-cook)
  ;  ]

end



to buy-alternative-groceries

  ;show ("I'm gonna buy an alternative product")

  ;create a list of available products minus the product that was not available


  let nr-dinner-guests count my-dinner-guests ;determine for how many people I need to buy ingredients

  ;check what other products that the meal i wanted to cook are available

  set supermarket-changes length sorted-food-outlets ;to prevent the cook from not being able to buy his requested product in the first supermarket of his choice

  let alt-sales-list []
  ;select a product that has sufficient stock, or buy nothing

  ;check if food outlet has required product still in stock for the quantity the cook needs
  ask my-supermarket [
    foreach diets-list [ diets ->

      let current-stock (table:get stock-table diets)
      ;show current-stock

      (ifelse current-stock >= nr-dinner-guests [

        set alt-sales-list fput diets alt-sales-list

        ]
        current-stock < nr-dinner-guests [
          ;do nothing
        ]
        ;if something goes wrong
        [show "I cannot determine for each product if it is sufficiently in stock"]
      )

    ]
    ;show alt-sales-list
  ]

  ; check if any of the alternative products are available sufficiently; if so, buy them, if not, go home hungry

  let length-alt-sales-list length alt-sales-list

  (ifelse length-alt-sales-list != 0 [

    let my-alternative-product one-of alt-sales-list
    let requested-product my-alternative-product
    set meal-to-cook my-alternative-product


    ;buy the alternative product
    ask my-supermarket [
      ;show stock-table
      foreach diets-list [ diets ->

        let current-stock (table:get stock-table diets)
        ;show stock-table
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


    ;the cook buys the product and adds his purchase to the sales of the food outlet
    if meal-to-cook != "none" [
      ;show (list requested-product nr-dinner-guests)
      ask my-supermarket [
        let current-sales (table:get sales-table requested-product)
        table:put sales-table requested-product (current-sales + nr-dinner-guests)

      ]

      set bought? true
    ]
    ]

    length-alt-sales-list = 0 [
      show "I cannot buy ingredients!"
    ]

    ;if the cook could not determine if there were any alternative products available
    [show "I do not know if there are any alternative products available"]
  )

end

to check-groceries

  ask persons with [is-cook? = true and meal-to-cook != "none" and bought? = false] [
    go-to-supermarket
  ]

end

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
        let my-meals-quality random-normal cooks-cooking-skills meal-quality-variance ;meal quality here is dependent of cooking skills of the cook: cooking skills +/- a standard deviation set in interface
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



          ;in this version people consider changing their diet preference after liking a meal several times, depending on their uncertainty avoidance
          (ifelse last-meal-enjoyment = "positive" [

            ;update table with meal enjoyments for each type of diet based on uncertainty avoidance
            let current-meal-enjoyment table:get meal-enjoyments-table my-last-dinner
            let update-meal-enjoyment uncertainty-avoidance > random-float 1 ;this evaluates to FALSE (I am too neophobic to consider liking new foods) to TRUE (I am neophilic enough to consider liking new foods)

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


    ;monitor diet preference of member with highest status
    ;    let vip-guest max-one-of members [status]
    ;    set vip-preference [diet] of vip-guest

  ]
end


to evaluate-meal



  ;dinner guests give status or substract status from their cook if they like or do not like the meal cooked, respectively
  if meal-evaluation = "quality-based" [

    ask persons with [is-cook? = false] [

      (ifelse last-meal-enjoyment = "negative" [
        ask my-cook [
          set status max (list 0 (status - status-increment))
        ]
      ] last-meal-enjoyment = "positive" [
        ask my-cook [
          set status min (list 1 (status + status-increment))
        ]
      ] [
        ;if no last-meals-quality was calcualted
        print (word who " was not able to judge my meal! last-meal-enjoyment = \"" last-meal-enjoyment "\" ; last-meals-quality = \"" last-meals-quality "\"")
      ])

    ]
  ]


  ;dinner guests give status or substract status from their cook if the cook has higher or lower status than themselves
  ;cooks give or substract status from their dinner guests if they liked or disliked the meal, respectively
  if meal-evaluation = "status-based" [

    ;dinner guests distribute status
    ask persons with [is-cook? = false][

      let my-status status
      let status-of-my-cook [status] of my-cook
      ;print (list who my-status my-cook status-of-my-cook)

      (ifelse my-status < status-of-my-cook or my-status = status-of-my-cook [ ;if my cook has a higher status than myself or the same status, I will always show gratitude for the meal, even if I don't like it
        ask my-cook [
          ;print "my status is being increased because my dinner guests liked what I cooked for them"
          set status min (list 1 (status + status-increment))
        ]
        ]

        my-status > status-of-my-cook and last-meal-enjoyment = "positive" [
          ask my-cook [
            ;print "my status is being increased because my dinner guests liked what I cooked for them"
            set status min (list 1 (status + status-increment))
          ]
        ]

        my-status > status-of-my-cook and last-meal-enjoyment = "negative" [
          ask my-cook [
            ;print ("my status is being reduced because my dinner guests did not like the meal I cooked for them"
            set status max (list 0 (status - status-increment)) ;if the cook has lower status than myself and I don't like the meal, I will say so
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

        (ifelse last-meal-enjoyment = "positive" [
          set status min (list 1 (status + status-increment))
          ]

          last-meal-enjoyment = "negative" and cooks-status > status [
            ;print "my status is being reduced because I did not like the meal"
            set status max (list 0 (status - status-increment))
          ]

          last-meal-enjoyment = "negative" and (cooks-status < status or cooks-status = status) [ ;when the cooks status is lower or similar to that of the guests and the experience is negative, the cook will still give status
                                                                                                  ;print "my status is being increased because I am considered important by the cook"
            set status min (list 1 (status + status-increment))
          ]

          ;if no last-meal-enjoyment
          [print (list who "I do not have an opinion about the last meal I had!")]

        )

      ]
    ]




  ]




end

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
              round (potential-costumers / nr-products) * stock-multiplication-factor
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
      ;print (word who " " stock-check " " diets)


      if stock-check = 0 [
        ;set error? true
        show (word "I am out of " diets)
        ;show stock-table
      ]
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


to visualization
  ask persons [

    ;set size according to status
    (ifelse status <= 0.25 [
      set size 1
      ]
      status > 0.25 and status <= 0.5 [
        set size 1.2
      ]
      status > 0.5 and status <= 0.75 [
        set size 1.4
      ]
      status > 0.75 and status <= 1 [
        set size 1.6
      ]
      ;if status exceeds 1
      [set size 1.8]
    )

    ;set label according to cooking skills
    set label (precision cooking-skills 1)
    set label-color white

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
409
10
1095
697
-1
-1
20.55
1
10
1
1
1
0
0
0
1
-16
16
-16
16
0
0
1
ticks
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
13
93
186
126
initial-nr-households
initial-nr-households
1
100
31.0
5
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
7
539
162
599
current-seed
1.919094976E9
1
0
Number

SWITCH
170
540
283
573
fixed-seed?
fixed-seed?
1
1
-1000

PLOT
1095
468
1322
694
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
1095
13
1321
241
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
1607
488
1835
684
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

SLIDER
1846
263
2019
296
max-cs-meat
max-cs-meat
0
1
0.75
0.01
1
NIL
HORIZONTAL

SLIDER
1843
304
2016
337
max-cs-fish
max-cs-fish
0
1
0.5
0.01
1
NIL
HORIZONTAL

SLIDER
1846
346
2019
379
max-cs-veget
max-cs-veget
0
1
0.56
0.01
1
NIL
HORIZONTAL

SLIDER
1846
386
2019
419
max-cs-vegan
max-cs-vegan
0
1
0.08
0.01
1
NIL
HORIZONTAL

CHOOSER
9
626
173
671
meal-selection
meal-selection
"status-based" "skills-based" "data-based" "majority" "collectivism" "random" "norm-random" "uncertainty-avoidance" "cook-individualism"
6

SLIDER
7
294
180
327
p-me
p-me
0
1
0.9
0.01
1
NIL
HORIZONTAL

SLIDER
7
334
180
367
p-fi
p-fi
0
1
0.02
0.01
1
NIL
HORIZONTAL

SLIDER
189
294
362
327
p-vt
p-vt
0
1
0.06
0.01
1
NIL
HORIZONTAL

SLIDER
185
336
358
369
p-vn
p-vn
0
1
0.06
0.01
1
NIL
HORIZONTAL

SLIDER
13
135
186
168
mean-family-size
mean-family-size
0
10
3.0
1
1
NIL
HORIZONTAL

SLIDER
12
174
185
207
sd-family-size
sd-family-size
0
2
1.0
1
1
NIL
HORIZONTAL

SLIDER
182
646
355
679
meal-quality-variance
meal-quality-variance
0
0.25
0.1
0.01
1
NIL
HORIZONTAL

CHOOSER
7
676
146
721
meal-evaluation
meal-evaluation
"quality-based" "status-based"
0

SWITCH
10
439
123
472
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
1600
10
1826
244
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
182
605
355
638
collectivism-dim
collectivism-dim
0
1
0.9
0.01
1
NIL
HORIZONTAL

SWITCH
130
440
250
473
dynamic-cs?
dynamic-cs?
1
1
-1000

SLIDER
11
213
184
246
nr-friends
nr-friends
2
10
2.0
1
1
NIL
HORIZONTAL

SLIDER
107
374
280
407
status-increment
status-increment
0
0.01
0.001
0.001
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
1852
244
1989
262
Quality-based sliders
10
0.0
1

TEXTBOX
14
602
151
620
SCENARIOS
10
0.0
1

TEXTBOX
14
519
151
537
RUN CONTROLS
10
0.0
1

SLIDER
195
92
367
125
initial-nr-food-outlets
initial-nr-food-outlets
0
10
8.0
1
1
NIL
HORIZONTAL

SLIDER
9
256
184
289
food-outlet-service-area
food-outlet-service-area
0
16
15.0
1
1
NIL
HORIZONTAL

SWITCH
10
479
167
512
food-outlet-interaction?
food-outlet-interaction?
0
1
-1000

PLOT
1596
244
1831
471
median product sales of food outlets
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
"default" 1.0 0 -6459832 true "" "plot meat-sales"
"pen-1" 1.0 0 -2064490 true "" "plot fish-sales"
"pen-2" 1.0 0 -4079321 true "" "plot vegetarian-sales"
"pen-3" 1.0 0 -13840069 true "" "plot vegan-sales"

PLOT
1094
239
1321
469
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
190
175
362
208
lower-margin
lower-margin
0
1
0.2
0.01
1
NIL
HORIZONTAL

SLIDER
189
215
361
248
upper-margin
upper-margin
0
1
0.6
0.01
1
NIL
HORIZONTAL

SLIDER
192
134
364
167
no-sales-threshold
no-sales-threshold
0
365
120.0
10
1
NIL
HORIZONTAL

TEXTBOX
20
416
170
434
SWITCHES
10
0.0
1

SWITCH
170
478
304
511
shops-sustainable?
shops-sustainable?
1
1
-1000

SWITCH
308
479
406
512
restocking?
restocking?
0
1
-1000

PLOT
407
704
607
854
check doing groceries
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
"default" 1.0 0 -16777216 true "" "plot count persons with [is-cook? = true]"
"pen-1" 1.0 0 -7500403 true "" "plot count persons with [bought? = true]"

SLIDER
187
255
364
288
stock-multiplication-factor
stock-multiplication-factor
1
10
2.0
1
1
NIL
HORIZONTAL

SWITCH
256
440
392
473
price-influence?
price-influence?
1
1
-1000

PLOT
1324
469
1607
698
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
290
541
393
574
error?
error?
1
1
-1000

PLOT
1325
14
1594
239
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
1325
243
1595
471
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
NetLogo 6.3.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="friendships-on-off" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="365"/>
    <metric>current-seed</metric>
    <metric>diet-variety-networks</metric>
    <metric>count persons with [diet = "meat"]</metric>
    <metric>count persons with [diet = "fish"]</metric>
    <metric>count persons with [diet = "vegetarian"]</metric>
    <metric>count persons with [diet = "vegan"]</metric>
    <enumeratedValueSet variable="restocking?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nr-friends">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="status-increment">
      <value value="0.001"/>
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
      <value value="110"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-family-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-nr-households">
      <value value="56"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="meal-evaluation">
      <value value="&quot;quality-based&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stock-multiplication-factor">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-nr-food-outlets">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="shops-sustainable?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-family-size">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-vt">
      <value value="0.06"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="upper-margin">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-cs-veget">
      <value value="0.56"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-fi">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-cs-vegan">
      <value value="0.08"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-outlet-service-area">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-vn">
      <value value="0.06"/>
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
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="friendships?">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-me">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="collectivism-dim">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="meal-selection">
      <value value="&quot;norm-random&quot;"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="restocking_sustainable-shops" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="365"/>
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
      <value value="0.001"/>
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
      <value value="110"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sd-family-size">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-nr-households">
      <value value="56"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="meal-evaluation">
      <value value="&quot;quality-based&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="stock-multiplication-factor">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-nr-food-outlets">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="shops-sustainable?">
      <value value="false"/>
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="mean-family-size">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-vt">
      <value value="0.06"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="upper-margin">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-cs-veget">
      <value value="0.56"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-fi">
      <value value="0.02"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-cs-vegan">
      <value value="0.08"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="food-outlet-service-area">
      <value value="15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-vn">
      <value value="0.06"/>
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
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="friendships?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="p-me">
      <value value="0.9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="collectivism-dim">
      <value value="0.9"/>
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
