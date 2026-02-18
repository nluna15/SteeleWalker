import Foundation

/// Curated list of breeds + mixed options seeded into the `breeds` Firestore
/// collection on first app launch (or via a Firebase admin script).
///
/// Usage: iterate `BreedSeed.all` and write each entry to `breeds/{id}`.
/// The `id` values are stable slugs so the seed is idempotent.
enum BreedSeed {

    struct Entry {
        let id: String      // stable slug used as Firestore document ID
        let name: String
        let isActive: Bool
    }

    // MARK: - Seed list

    static let all: [Entry] = purebreds + mixedBreeds

    // MARK: - Purebreds (alphabetical)

    private static let purebreds: [Entry] = [
        Entry(id: "affenpinscher",            name: "Affenpinscher",              isActive: true),
        Entry(id: "akita",                    name: "Akita",                      isActive: true),
        Entry(id: "alaskan-malamute",         name: "Alaskan Malamute",           isActive: true),
        Entry(id: "american-staffordshire",   name: "American Staffordshire Terrier", isActive: true),
        Entry(id: "australian-cattle-dog",    name: "Australian Cattle Dog",      isActive: true),
        Entry(id: "australian-shepherd",      name: "Australian Shepherd",        isActive: true),
        Entry(id: "basset-hound",             name: "Basset Hound",               isActive: true),
        Entry(id: "beagle",                   name: "Beagle",                     isActive: true),
        Entry(id: "belgian-malinois",         name: "Belgian Malinois",           isActive: true),
        Entry(id: "bernese-mountain-dog",     name: "Bernese Mountain Dog",       isActive: true),
        Entry(id: "bichon-frise",             name: "Bichon Frisé",               isActive: true),
        Entry(id: "bloodhound",               name: "Bloodhound",                 isActive: true),
        Entry(id: "border-collie",            name: "Border Collie",              isActive: true),
        Entry(id: "border-terrier",           name: "Border Terrier",             isActive: true),
        Entry(id: "boston-terrier",           name: "Boston Terrier",             isActive: true),
        Entry(id: "boxer",                    name: "Boxer",                      isActive: true),
        Entry(id: "bull-terrier",             name: "Bull Terrier",               isActive: true),
        Entry(id: "bulldog",                  name: "Bulldog",                    isActive: true),
        Entry(id: "cairn-terrier",            name: "Cairn Terrier",              isActive: true),
        Entry(id: "cavalier-kcs",             name: "Cavalier King Charles Spaniel", isActive: true),
        Entry(id: "chihuahua",                name: "Chihuahua",                  isActive: true),
        Entry(id: "chow-chow",                name: "Chow Chow",                  isActive: true),
        Entry(id: "cocker-spaniel",           name: "Cocker Spaniel",             isActive: true),
        Entry(id: "dachshund",                name: "Dachshund",                  isActive: true),
        Entry(id: "dalmatian",                name: "Dalmatian",                  isActive: true),
        Entry(id: "doberman-pinscher",        name: "Doberman Pinscher",          isActive: true),
        Entry(id: "english-springer-spaniel", name: "English Springer Spaniel",   isActive: true),
        Entry(id: "french-bulldog",           name: "French Bulldog",             isActive: true),
        Entry(id: "german-shepherd",          name: "German Shepherd",            isActive: true),
        Entry(id: "german-shorthaired-pointer", name: "German Shorthaired Pointer", isActive: true),
        Entry(id: "golden-retriever",         name: "Golden Retriever",           isActive: true),
        Entry(id: "great-dane",               name: "Great Dane",                 isActive: true),
        Entry(id: "greyhound",                name: "Greyhound",                  isActive: true),
        Entry(id: "havanese",                 name: "Havanese",                   isActive: true),
        Entry(id: "irish-setter",             name: "Irish Setter",               isActive: true),
        Entry(id: "italian-greyhound",        name: "Italian Greyhound",          isActive: true),
        Entry(id: "jack-russell-terrier",     name: "Jack Russell Terrier",       isActive: true),
        Entry(id: "labrador-retriever",       name: "Labrador Retriever",         isActive: true),
        Entry(id: "leonberger",               name: "Leonberger",                 isActive: true),
        Entry(id: "lhasa-apso",               name: "Lhasa Apso",                 isActive: true),
        Entry(id: "maltese",                  name: "Maltese",                    isActive: true),
        Entry(id: "miniature-pinscher",       name: "Miniature Pinscher",         isActive: true),
        Entry(id: "miniature-schnauzer",      name: "Miniature Schnauzer",        isActive: true),
        Entry(id: "newfoundland",             name: "Newfoundland",               isActive: true),
        Entry(id: "papillon",                 name: "Papillon",                   isActive: true),
        Entry(id: "pembroke-welsh-corgi",     name: "Pembroke Welsh Corgi",       isActive: true),
        Entry(id: "pomeranian",               name: "Pomeranian",                 isActive: true),
        Entry(id: "poodle-miniature",         name: "Poodle (Miniature)",         isActive: true),
        Entry(id: "poodle-standard",          name: "Poodle (Standard)",          isActive: true),
        Entry(id: "poodle-toy",               name: "Poodle (Toy)",               isActive: true),
        Entry(id: "pug",                      name: "Pug",                        isActive: true),
        Entry(id: "rat-terrier",              name: "Rat Terrier",                isActive: true),
        Entry(id: "rottweiler",               name: "Rottweiler",                 isActive: true),
        Entry(id: "saint-bernard",            name: "Saint Bernard",              isActive: true),
        Entry(id: "samoyed",                  name: "Samoyed",                    isActive: true),
        Entry(id: "scottish-terrier",         name: "Scottish Terrier",           isActive: true),
        Entry(id: "shetland-sheepdog",        name: "Shetland Sheepdog",          isActive: true),
        Entry(id: "shiba-inu",                name: "Shiba Inu",                  isActive: true),
        Entry(id: "shih-tzu",                 name: "Shih Tzu",                   isActive: true),
        Entry(id: "siberian-husky",           name: "Siberian Husky",             isActive: true),
        Entry(id: "soft-coated-wheaten",      name: "Soft Coated Wheaten Terrier", isActive: true),
        Entry(id: "vizsla",                   name: "Vizsla",                     isActive: true),
        Entry(id: "weimaraner",               name: "Weimaraner",                 isActive: true),
        Entry(id: "west-highland-terrier",    name: "West Highland White Terrier", isActive: true),
        Entry(id: "whippet",                  name: "Whippet",                    isActive: true),
        Entry(id: "yorkshire-terrier",        name: "Yorkshire Terrier",          isActive: true),
    ]

    // MARK: - Mixed breeds

    /// High-level mixed options for dogs whose exact breed is unknown or blended.
    /// Listed at the top of the typeahead (sort weight handled client-side).
    private static let mixedBreeds: [Entry] = [
        Entry(id: "mix-general",          name: "Mixed - General",            isActive: true),
        Entry(id: "mix-labrador",         name: "Labrador Mix",               isActive: true),
        Entry(id: "mix-german-shepherd",  name: "German Shepherd Mix",        isActive: true),
        Entry(id: "mix-golden-retriever", name: "Golden Retriever Mix",       isActive: true),
        Entry(id: "mix-poodle",           name: "Poodle Mix",                 isActive: true),
        Entry(id: "mix-beagle",           name: "Beagle Mix",                 isActive: true),
        Entry(id: "mix-husky",            name: "Husky Mix",                  isActive: true),
        Entry(id: "mix-australian-shepherd", name: "Australian Shepherd Mix", isActive: true),
        Entry(id: "mix-border-collie",    name: "Border Collie Mix",          isActive: true),
        Entry(id: "mix-chihuahua",        name: "Chihuahua Mix",              isActive: true),
        Entry(id: "mix-terrier",          name: "Terrier Mix",                isActive: true),
        Entry(id: "mix-hound",            name: "Hound Mix",                  isActive: true),
        Entry(id: "mix-spaniel",          name: "Spaniel Mix",                isActive: true),
        Entry(id: "mix-boxer",            name: "Boxer Mix",                  isActive: true),
        Entry(id: "mix-rottweiler",       name: "Rottweiler Mix",             isActive: true),
    ]
}
