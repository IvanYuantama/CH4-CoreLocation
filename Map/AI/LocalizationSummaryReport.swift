//
//  LocalizationSummaryReport.swift
//  test
//
//  Created by Benedict Kenjiro Lehot on 03/07/26.
//

import FoundationModels

@Generable
struct LocationSummaryReport {
    @Guide(description: """
    A single flowing paragraph (not a list, not separate sentences per topic) describing 
    this location for a general audience. The paragraph must weave together information 
    in this exact topic order: (1) flood risk, (2) temperature, (3) air quality, 
    (4) green spaces, (5) population, (6) elevation, (7) road access, 
    (8) nearby public facilities, (9) wifi connectivity, (10) mobile data connectivity, 
    (11) crime rate. Blend transitions naturally between topics instead of writing 
    one isolated sentence per topic. Keep it strictly under 45 words total.
    """)
    let narrative: String
}
