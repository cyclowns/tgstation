//  PIPENET DATUMS
//
//  In the past, pipenet datum code was so buggy
//  that one man decided to rewrite the entire
//  thing from the ground up. You can thank me
//  for that.
//
//  One of the main issues with pipenet datums
//  of ye olde is that they were 100% undocumented,
//  they had no good debugging methods, and most of
//  the code was very unintuitive at first glance. 
//  Obviously those are some pretty big problems.
//
//  Some pipenet code is loosely (okay heavily) based 
//  off of powernet code, mostly because I've never
//  seen powernets fuck up and die before.
//
//  Some pipenet terminology that will stay consistent throughout the code:
//  - air/air contents: Main gas contained within the members of the pipenet. other_air_contents will be referred to specifically as such.
//  - member:           Pipe within a pipenet, as opposed to a machine.
//  - machine:          Atmospheric machine within the pipenets - vents, cryo tubes, etc, as opposed to a pipe.
//  - nodes:            Catch-all term for either a member or a machine. Used to generalize the two as a single concept.
//  - connection:       Connection (obviously) between two nodes.
//
//  For explanation on how pipenets work, most vars
//  and procs are documented fairly well below.

/datum/pipenet
    var/id                                // Unique identifier
    var/datum/gas_mixture/air_contents    // Main air contents of the pipenet. This is the gas that is contained within the pipes ('members') of the pipenet.
    var/list/other_air_contents = list()  // Other air contents of the pipenet, such as those contained within connected canisters.
    
    var/list/members = list()             // All pipes or 'members' as they will referred to from now on within the pipenet.
    var/list/machinery = list()           // All atmospheric machinery within the pipenet - vents, cryo tubes, etc.

// Called when a new pipenet is created.
/datum/pipenet/New()
    SSair.pipenets += src

// Called when a pipenet is destroyed.
/datum/pipenet/Destroy()
    // Try to get rid of all references first
    for(var/obj/machinery/atmospherics/pipe/P in members)
        members -= P
        P.pipenet = null
    for(var/obj/machinery/atmospherics/components/C in machinery)
        machinery -= C
        C.pipenet = null

    SSair.pipenets -= src
    return ..()

// Helper functions
/datum/pipenet/is_empty()
    return !members.len && !machinery.len

// Returns true if the given node is both listed as having us as their pipenet, and is actually contained within the node lists
/datum/pipenet/contains_node(obj/machinery/atmospherics/N)
    return (N.pipenet == src) && ((N in members) || (N in machinery))

// Adds member to pipenet
/datum/pipenet/add_member(obj/machinery/atmospherics/pipe/P)
    if(P.pipenet) // Already has a pipenet
        if(contains_node(C)) // ...it's us?
            return
        else
            P.pipenet.remove_member(P) // It doesn't need them anymore
    P.pipenet = src
    members += P

// Removes member from pipenet
// If the pipenet is empty, then we delete it
/datum/pipenet/remove_member(obj/machinery/atmospherics/pipe/P)
    members -= P
    P.pipenet = null
    if(is_empty()) // Nothing left after we removed that member?
        qdel(src) // Guess I'll die

// Adds machine to pipenet
/datum/pipenet/add_machine(obj/machinery/atmospherics/components/C)
    if(C.pipenet) // Already has a pipenet
        if(contains_node(C)) // ...it's us?
            return
        else
            C.pipenet.remove_machine(C) // It doesn't need them anymore
    C.pipenet = src
    members += C

// Removes machine from pipenet
// If the pipenet is empty afterwards, then we delete it
/datum/pipenet/remove_machine(obj/machinery/atmospherics/components/C)
    machinery -= C
    C.pipenet = null
    if(is_empty()) // Nothing left after we removed that machine?
        qdel(src) // Guess I'll die