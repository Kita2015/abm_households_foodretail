;; version 0.2 ;;

extensions [ rnd table ]


;;;;;;;;;;;;;;;;;;;;;
;; state variables ;;
;;;;;;;;;;;;;;;;;;;;;

breed [ persons person ]
breed  [ households household ]
;breed  [ food_outlets food_outlet ]
breed [ foods food ]

;directed-link-breed [ parents parent ]
undirected-link-breed [friends friend ] ;assumption: friendships are mutual experiences
undirected-link-breed [family-members family-member]
directed-link-breed [household-members household-member]


globals [
  diet-list
  ;income-levels
  id-households
  cooked-meat
  cooked-fish
  cooked-vegetarian
  cooked-vegan
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
  meal-i-cooked
  my-last-dinner
  last-meals-quality
  last-meal-enjoyment
  my-cook
  my-dinner-guests
  ;egoism
  status
  at-home?
]

households-own [
  ;income-level
  id ; identifier
  members
  meal-cooked?
  empty-house?
]

;food_outlets-own [
;  assortment
;  sales
;  business-orientation
;  susceptibility-to-demand
;]

foods-own [
  protein-type
  serves-diet
  ;price
  ;availability
]

to setup
  clear-all
  setup-seed
  setup-globals
  setup-households
  setup-persons
  setup-families
  show-families
  setup-friendships
  visualization
  ;setup-food_outlets
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
  ;set income-levels ["low" "middle" "high"]
  set id-households 0
  set cooked-meat 0
  set cooked-fish 0
  set cooked-vegetarian 0
  set cooked-vegan 0

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
    let new-family random-normal mean-family-size sd-family-size
    let new-family-abs abs new-family
    hatch-persons new-family-abs + 1
    set empty-house? false
    set meal-cooked? false
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
    set meal-i-cooked "none"
    set cooking-skills random-float 1
    set status random-float 1
    set my-last-dinner "none"
    set last-meals-quality "none"
    set last-meal-enjoyment "none"
    set cooks-cooking-skills 0
    set my-cook "nobody"
    set my-dinner-guests "nobody"
    set cs-meat random-float max-cs-meat
    set cs-fish random-float max-cs-fish
    set cs-veget random-float max-cs-veget
    set cs-vegan random-float max-cs-vegan
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
    create-family-members-with my-family [set color pink] ; persons create family bonds
    let my-house households with [id = [h-id] of myself]
    create-household-member-from one-of my-house [set color 37]
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
      let nr-friendships random 2 ;people will create 0 or 1 friends
      repeat nr-friendships [create-friend-with one-of potential-friends [set color 9.9]]
    ]
  ]
  ;friendships? = false
  [
    ;do nothing
  ]
end


;to setup-food_outlets
;  ;;;
;end

;to setup-foods
;
;end

to go

  if ticks = 365 [stop]

  closure-meals
  select-group-and-cook
  select-meal
  evaluate-meal
  visualization


  tick

end

to closure-meals ;person and household procedure
  ask persons with [is-cook? = true ] [
    set meal-i-cooked "none"
    set is-cook? false
    set my-dinner-guests "nobody"
  ]

  ask persons with [is-cook? = false ] [
    set cooks-cooking-skills "none"
    set last-meal-enjoyment "none"
  ]

  ask persons with [at-home? = false] [
    let my-home one-of households with [id = [h-id] of myself]
    move-to my-home
    set at-home? true
    left random 360
    forward 1
  ]

  ask persons [
    set my-cook "nobody"
  ]

  ask households [
    set meal-cooked? false
    set empty-house? false
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
      ;print (list who)

      ask todays-cook [
        set is-cook? true
        set cooking-skills max (list 1 (cooking-skills + 0.01))
        set my-dinner-guests todays-dinner-guests ;gather group for meal - for now this is only the family members, not friends



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
          set cooking-skills max (list 1 (cooking-skills + 0.01))

          let nr-dinner-friends count friend-neighbors with [at-home? = true]


          ;;if the cook has no friends
          ifelse nr-dinner-friends = 0 [
            set my-dinner-guests todays-dinner-guests ;do not invite friends because I do not have any
          ]

          ;;if the cook does have friends
          ;nr-dinner friends != 0
          [

            let dinner-friends friend-neighbors with [at-home? = true and is-cook? = false] ;only invite friends who are still at home and do not have to cook for their own household
            ask dinner-friends [
              set at-home? false
              move-to patch-here
            ]

            let dinner-members family-member-neighbors with [at-home? = true]
            set my-dinner-guests (turtle-set dinner-members dinner-friends self)

          ]

          ask my-dinner-guests [
            set my-cook todays-cook ;setting todays cook for all dinner-group members
                                    ;print (list who my-cook) ;they all print themselves as my-cook
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
  ask households [
    ifelse empty-house? = true [
      ;do not run this procedure
    ]

    ;empty-house = false
    ;run this procedure
    [


      ask persons with [is-cook? = true]  [

        (ifelse meal-selection = "status-based" [

          ;;procedure to select status-based a meal


          let vip-guest max-one-of my-dinner-guests [status] ;choose guest with highest status; this could in this model version also be himself
          let vip-meal "none"
          ask vip-guest [
            set vip-meal [diet] of self ;ask guest with highest status to select meal
          ]
          set meal-i-cooked vip-meal   ;cook has decided to cook meal preference of vip-guest
          set my-last-dinner vip-meal

          ;guests store meal they had and cooking skills of cook
          let my-cooking-skills [cooking-skills] of self

          ask my-dinner-guests [ ;cook asks his guests to set last meal to the meal he cooked
            set my-last-dinner vip-meal
            set cooks-cooking-skills my-cooking-skills
          ] ;cook asks his guests to store his cooking skills for evaluation in the next procedure...

          ]

          meal-selection = "skills-based" [

            ;; procedure to select skills-based a meal

            let list-my-cs-names (list "meat" "fish" "vegetarian" "vegan") ;create list of diets / meals. Used diet names here instead of cs-[diet] to enable transfer to chosen-meal and plot of cooked meals
            let list-my-cs-values (list cs-meat cs-fish cs-veget cs-vegan) ;create list of cooking skills values
            let list-my-cs table:from-list (map list list-my-cs-values list-my-cs-names) ;create table with cooking skill for each diet / meal
            let my-best-cs max list-my-cs-values ;select the best cooking skill
            let chosen-meal table:get list-my-cs my-best-cs ;use the best cooking skill value to select the diet / meal

            set meal-i-cooked chosen-meal   ;cook decides what type of meal to prepare
            set my-last-dinner chosen-meal



            ask my-dinner-guests [ ;cook asks his guests to set last meal to the meal he cooked
              set my-last-dinner chosen-meal
              set cooks-cooking-skills [cooking-skills] of myself ;myself is the cook here
            ]
          ]

          meal-selection = "majority" [

            ;;procedure to select meal democratically


            let dinner-list-majority [ (list diet) ] of my-dinner-guests

            let freq-list map [ i -> frequency I dinner-list-majority] dinner-list-majority ;creates a list with for each diet on dinner-list-majority how frequent it appears in dinner-list-majority
                                                                                            ;print freq-list
            let dinner-freq-list table:from-list (map list freq-list dinner-list-majority) ;creates a table with the frequency for each diet on the dinner-list majority
                                                                                           ;print dinner-freq-list
            let count-majority-choice max freq-list ;select the highest count
                                                    ;print count-majority-choice
            let chosen-meal-list table:get dinner-freq-list count-majority-choice ;use highest count to select the diet with this highest count
                                                                                  ;print chosen-meal-list
            let chosen-meal first chosen-meal-list ;unpack diet / meal from list
                                                   ;print chosen-meal

            set meal-i-cooked chosen-meal   ;cook decides what type of meal to prepare
            set my-last-dinner chosen-meal

            ask my-dinner-guests [ ;cook asks his guests to set last meal to the meal he cooked
              set my-last-dinner chosen-meal
              set cooks-cooking-skills [cooking-skills] of myself ;myself is the cook here
            ]


          ]

          meal-selection = "random" [

            ;;procedure to select meal randomly


            let dinner-list [ (list who diet ) ] of my-dinner-guests
            ;print dinner-list


            let chosen-meal item 1 (first dinner-list) ;choose first diet on the list, so the second item in the first list; a random choice
            set meal-i-cooked chosen-meal   ;cook decides what type of meal to prepare
            set my-last-dinner chosen-meal

            ask my-dinner-guests [ ;cook asks his guests to set last meal to the meal he cooked
              set my-last-dinner chosen-meal
              set cooks-cooking-skills [cooking-skills] of myself ;myself is the cook here
            ]
          ]

          [
            ;if no meal-selection option has been selected
            print("We do not know how to select our meal!")
          ]

        )


      ]
    ]
  ]

end

to evaluate-meal

  ask households [
    ifelse empty-house? = true [
      ;do not run this procedure
    ]

    ;empty-house = false
    ;run this procedure
    [


      ;set the meal evaluation
      ask persons [

        set last-meals-quality random-normal cooks-cooking-skills meal-quality-variance ;meal quality here is dependent of cooking skills of the cook: cooking skills +/- a standard deviation set in interface

        (ifelse last-meals-quality < 0.55 [
          set last-meal-enjoyment "negative"
          ]
          last-meals-quality >= 0.55 [
            set last-meal-enjoyment "positive"
          ]
          ;if no meal evaluation took place
          [print "I did not evaluate the meal I just had!"]
        )


        ;in this version people consider changing their diet preference if they enjoyed their meal based only on a binary enjoyment outcome
        ifelse last-meal-enjoyment = "positive" [
          set diet [my-last-dinner] of self ;agent uses last meal he had to set new diet preference
        ] [
          ;do nothing - keep my current preference. I did not like the meal that my-cook served me.
        ]
      ]


      ;dinner guests give status or substract status from their cook if they like or do not like the meal cooked, respectively
      if meal-evaluation = "quality-based" [

        ask persons with [is-cook? = false][

          set last-meals-quality random-normal cooks-cooking-skills meal-quality-variance ;meal quality here is dependent of cooking skills of the cook: cooking skills +/- a standard deviation set in interface

          (ifelse last-meal-enjoyment = "negative" [
            ask my-cook [set status max (list 1 (status - 0.02))] ;status loss is more severe than status gain
            ]
            last-meal-enjoyment = "positive" [
              ask my-cook [set status max (list 1 (status + 0.01))]
            ]

            ;if no last-meals-quality was calcualted
            [print "I was not able to judge my meal!"]

          )

        ]
      ]


      ;dinner guests give status or substract status from their cook if the cook has higher or lower status than themselves
      ;cooks give or substract status from their dinner guests if they liked or disliked the meal, respectively
      if meal-evaluation = "status-based" [

        ;dinner guests distribute status
        ask persons with [is-cook? = false][

          let my-status status
          let status-of-my-cook [status] of my-cook

          (ifelse my-status < status-of-my-cook [ ;if my cook has a higher status than myself, I will always show gratitude for the meal, even if I don't like it
            ask my-cook [
              set status max (list 1 (status + 0.01))
            ]
            ]
            my-status > status-of-my-cook [
              ask my-cook [
                set status max (list 1 (status - 0.02)) ;if the cook has lower status than myself and I don't like the meal, I will say so
              ]
            ]

            ;if no input is selected for meal-evaluation, throw error
            [print "I do not know how to evaluate the meal!"]

          )
        ]

        ;cooks distribute status
        ask persons with [is-cook? = true][
          let cooks-status status
          ask my-dinner-guests with [is-cook? = false] [

            (ifelse last-meal-enjoyment = "positive" [
              set status max (list 1 (status + 0.01))
              ]

              last-meal-enjoyment = "negative" and cooks-status > status [
                ;print "my status is being reduced because I did not like the meal"
                set status max (list 1 (status - 0.02))
              ]

              last-meal-enjoyment = "negative" and cooks-status < status [
                ;print "my status is being increased because I am considered important by the cook"
                set status max (list 1 (status + 0.01))
              ]

              ;if no last-meal-enjoyment, meaning the person did not have dinner
              [print "I do not have an opinion about the last meal I !"]

            )

          ]
        ]
      ]
    ]
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
        print "I don't have a diet!"
      ]
    )

  ]

end



;;;;;;;;;;;;;;;
;; reporters ;;
;;;;;;;;;;;;;;;

to-report status-distribution
  report [status] of persons
end

to-report cooking-skills-distribution
  report [cooking-skills] of persons
end

to-report frequency [x freq-list]
  report reduce [ [occurrence-count next-item] -> ifelse-value (next-item = x) [occurrence-count + 1] [occurrence-count] ] (fput 0 freq-list)
end


;let fish-regeneration (fish-regeneration-factor * fish-stock * (1 - (fish-stock / 1000 ) ) ) ;limited growth
;    let fish-degeneration (water-pollution * fish-susceptibility) ;Do we show a relationship between water-pollution and fish-stock in the Loopy diagram?
;    set fish-stock (fish-stock + fish-regeneration - fish-degeneration)
@#$#@#$#@
GRAPHICS-WINDOW
377
10
1064
698
-1
-1
20.6
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
12
15
75
48
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
158
15
221
48
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
4
223
177
256
initial-nr-households
initial-nr-households
1
100
6.0
5
1
NIL
HORIZONTAL

BUTTON
85
14
148
47
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
3
626
158
686
current-seed
1.100034004E9
1
0
Number

SWITCH
170
628
283
661
fixed-seed?
fixed-seed?
1
1
-1000

PLOT
1071
12
1421
255
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
"meat" 1.0 0 -6459832 true "" "plot count persons with [meal-i-cooked = \"meat\"]"
"fish" 1.0 0 -1664597 true "" "plot count persons with [meal-i-cooked = \"fish\"]"
"vegetarian" 1.0 0 -4079321 true "" "plot count persons with [meal-i-cooked = \"vegetarian\"]"
"vegan" 1.0 0 -14439633 true "" "plot count persons with [meal-i-cooked = \"vegan\"]"

PLOT
1274
503
1497
699
distribution of cooking skills
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
"skills" 0.1 1 -16777216 true "" "histogram(cooking-skills-distribution)"

PLOT
1072
262
1422
496
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
1500
503
1728
699
distribution of status
NIL
NIL
-10.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 0.1 1 -16777216 true "" "histogram(status-distribution)"

SLIDER
192
138
365
171
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
190
178
363
211
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
192
220
365
253
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
192
260
365
293
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
13
519
153
564
meal-selection
meal-selection
"status-based" "skills-based" "majority" "random"
3

SLIDER
191
342
364
375
p-me
p-me
0
1
0.94
0.01
1
NIL
HORIZONTAL

SLIDER
192
385
365
418
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
194
426
367
459
p-vt
p-vt
0
1
0.02
0.01
1
NIL
HORIZONTAL

SLIDER
191
468
364
501
p-vn
p-vn
0
1
0.02
0.01
1
NIL
HORIZONTAL

SLIDER
10
140
183
173
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
6
181
179
214
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
2
266
175
299
meal-quality-variance
meal-quality-variance
0
0.5
0.5
0.01
1
NIL
HORIZONTAL

CHOOSER
12
569
151
614
meal-evaluation
meal-evaluation
"quality-based" "status-based"
1

SWITCH
166
521
279
554
friendships?
friendships?
1
1
-1000

TEXTBOX
15
63
152
127
LEGEND\nmeat = brown\nfish = pink\nveget = yellow\nvegan = green
10
0.0
1

PLOT
1072
504
1271
699
Persons in or out 
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"in" 1.0 0 -16777216 true "" "plot count persons with [at-home? = true]"
"out" 1.0 0 -4539718 true "" "plot count persons with [at-home? = false]"

SLIDER
3
340
175
373
p-me-cons
p-me-cons
0
1
0.8
0.01
1
NIL
HORIZONTAL

SLIDER
2
382
174
415
p-fi-cons
p-fi-cons
0
1
0.2
0.01
1
NIL
HORIZONTAL

SLIDER
1
426
173
459
p-vt-cons
p-vt-cons
0
1
0.05
0.01
1
NIL
HORIZONTAL

SLIDER
2
472
174
505
p-vn-cons
p-vn-cons
0
1
0.05
0.01
1
NIL
HORIZONTAL

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
