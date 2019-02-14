ruleset temperature_store{
    meta {
    }

    global{
    }

    rule collect_temperatures{
        select when wovyn new_temperature_reading
    }

}


