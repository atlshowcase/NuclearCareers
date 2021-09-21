//
//  NuclearCareer.swift
//  Future Of Nuclear
//
//  Created by Technology Showcase on 1/2/18.
//  Copyright © 2018 InventiApps. All rights reserved.
//

import Foundation
class NuclearCareer
{
    var id = 0
    
    var name = "Name of Career"
    var description = "Description of Career"
    var headImage = "filename of head image"
    var bodyImage = "filename of body image"
    var propImage = "filename of prop image"
    
    var names =
    [
        "Security",
        "Chemist",
        "Technician",
        "Welder"
    ]
    var descriptions =
    [
        "I’m a nuclear security officer. I conduct patrols and investigations to maintain the safety and security of the plant and employees from potential threats. I have previous experience as a member of law enforcement, the military or a security role.",
        "I’m a chemistry technician. I sample the chemical properties of various plant equipment, systems and the surrounding environment to conduct lab testing and interpret results. I possess a four-year degree in chemistry or a related field.",
        "I’m a nuclear technician. I troubleshoot, test and inspect mechanical or electrical components to make sure the plant operates efficiently. I may have a specialized associate degree or previous experience.",
        "I’m a nuclear welder. I fuse parts, steel structures or other components to construct new nuclear facilities and to operate existing plants. I have a certification through the American Welding Association and may have additional qualifications."
    ]
    var headPaths =
    [
        "security_head",
         "chemist_head",
         "technician_head",
         "welder_head"
    ]
    var bodyPaths =
    [
        "security_body",
        "chemist_body",
        "technician_body",
        "welder_body"
    ]
    var propPaths =
    [
        "security_prop",
        "chemist_prop",
        "",
        "welder_prop"
    ]
    
    func update(newID:Int)
    {
        // I swear to fucking god if you pass a negative variable i'm gonna find you and bury you in elephant dung
        id = newID
        name = names[id]
        description = descriptions[id]
        headImage = headPaths[id]
        bodyImage = bodyPaths[id]
        propImage = propPaths[id]
    }
    
    
    func getID()->Int
    {
        return id
    }
    func getName()->String
    {
        return name
    }
    func getDescription()->String
    {
        return description
    }
    func getHeadImage()->String
    {
        return headImage
    }
    func getBodyImage()->String
    {
        return bodyImage
    }
    func getPropImage()->String
    {
        return propImage
    }
}
