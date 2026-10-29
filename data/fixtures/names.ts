/**
 * Fictional name, address, contact-info pools for the Northgate Motors generator.
 * No real people, no deliverable email domains, no real phone numbers.
 * Domains are reserved .test per DEMO_ORG_SYNTHETIC_DATA_PLAN.md §11.
 */

const FIRST_NAMES: string[] = [
    'Alex', 'Avery', 'Bailey', 'Cameron', 'Casey', 'Dakota', 'Drew', 'Emerson', 'Finley', 'Harper',
    'Hayden', 'Jamie', 'Jordan', 'Kai', 'Kendall', 'Logan', 'Mackenzie', 'Morgan', 'Parker', 'Quinn',
    'Reese', 'Riley', 'Sage', 'Skyler', 'Sloane', 'Soren', 'Tatum', 'Toby', 'Wren', 'Ainsley',
    'Anders', 'Bex', 'Coda', 'Devon', 'Eden', 'Frey', 'Gale', 'Hollis', 'Indie', 'Joss',
    'Kairos', 'Lane', 'Marin', 'Niko', 'Onyx', 'Pax', 'Quill', 'Rune', 'Sol', 'Tess',
    'Uri', 'Vesper', 'Wynn', 'Xan', 'Yara', 'Zion', 'Arrow', 'Briar', 'Cinder', 'Dune',
    'Ember', 'Frost', 'Glimmer', 'Holt', 'Indigo', 'Juno', 'Kestrel', 'Lark', 'Meridian', 'Nimbus',
    'Onyx', 'Phoenix', 'Quill', 'Riven', 'Solace', 'Tide', 'Vale', 'Wren', 'Xander', 'Yarrow',
    'Zephyr', 'Ash', 'Briar', 'Clio', 'Dove', 'Echo', 'Fern', 'Glen', 'Hawk', 'Iris',
    'Jade', 'Kite', 'Lark', 'Maple', 'Nova', 'Owl', 'Pine', 'Quill', 'Raven', 'Sage',
    'Tate', 'Vale', 'Willow', 'Yara', 'Zion', 'Aspen', 'Birch', 'Cedar', 'Drift', 'Elm',
    'Frost', 'Glen', 'Holly', 'Ivy', 'Juniper', 'Kelp', 'Lichen', 'Moss', 'Nettle', 'Oak',
];

const LAST_NAMES: string[] = [
    'Adams', 'Allen', 'Anderson', 'Bailey', 'Baker', 'Barnes', 'Bell', 'Bennett', 'Brooks', 'Brown',
    'Campbell', 'Carter', 'Chen', 'Clark', 'Coleman', 'Collins', 'Cook', 'Cooper', 'Cox', 'Davis',
    'Diaz', 'Edwards', 'Evans', 'Fisher', 'Foster', 'Garcia', 'Gomez', 'Gonzalez', 'Gray', 'Green',
    'Hall', 'Harris', 'Henderson', 'Hill', 'Howard', 'Jackson', 'James', 'Jenkins', 'Johnson', 'Jones',
    'Kelly', 'King', 'Lee', 'Lewis', 'Long', 'Lopez', 'Martin', 'Martinez', 'Mitchell', 'Moore',
    'Morgan', 'Morris', 'Murphy', 'Nelson', 'Nguyen', 'Parker', 'Patel', 'Perez', 'Phillips', 'Powell',
    'Price', 'Reed', 'Reyes', 'Richardson', 'Rivera', 'Roberts', 'Robinson', 'Rodriguez', 'Rogers', 'Ross',
    'Russell', 'Sanchez', 'Sanders', 'Scott', 'Simmons', 'Smith', 'Stewart', 'Sullivan', 'Taylor', 'Thomas',
    'Thompson', 'Torres', 'Turner', 'Walker', 'Ward', 'Washington', 'Watson', 'White', 'Williams', 'Wilson',
    'Wood', 'Wright', 'Young', 'Zimmerman', 'Achebe', 'Barros', 'Costa', 'Dias', 'Fonseca', 'Gomes',
    'Lopes', 'Marques', 'Mendes', 'Nunes', 'Oliveira', 'Pereira', 'Pinto', 'Ribeiro', 'Santos', 'Silva',
    'Sousa', 'Teixeira', 'Vieira', 'Carvalho', 'Cunha', 'Barros', 'Ferreira', 'Moura', 'Almeida', 'Cardoso',
];

const STREETS: string[] = [
    'Maple', 'Oak', 'Pine', 'Cedar', 'Birch', 'Elm', 'Ash', 'Walnut', 'Cherry', 'Magnolia',
    'Cypress', 'Juniper', 'Willow', 'Aspen', 'Beech', 'Holly', 'Ivy', 'Myrtle', 'Olive', 'Sequoia',
    'River', 'Lake', 'Hill', 'Meadow', 'Valley', 'Ridge', 'Glen', 'Park', 'Garden', 'Forest',
    'Sunset', 'Sunrise', 'Harbor', 'Bay', 'Cove', 'Beach', 'Island', 'Lighthouse', 'Bridge', 'Wharf',
];

const STREET_SUFFIXES = ['St', 'Ave', 'Rd', 'Blvd', 'Cres', 'Way', 'Pl', 'Lane', 'Ct', 'Ter'];

const ONTARIO_CITIES = ['Toronto', 'Mississauga', 'Brampton', 'Vaughan', 'Markham', 'Oakville', 'Burlington', 'Richmond Hill'];

const ONTARIO_PROVINCES = ['ON'];

// 555-01xx is the fictional 555-01xx range per plan §3.
function pickPhoneRand(rand: () => number): string {
    const area = pickOne(rand, ['416', '905', '289']);
    const tail = (10 + Math.floor(rand() * 89)).toString().padStart(2, '0');
    return `+1 ${area}-555-01${tail}`;
}

function pickOne<T>(rand: () => number, arr: readonly T[]): T {
    return arr[Math.floor(rand() * arr.length)]!;
}

export function pickFirst(rand: () => number): string {
    return pickOne(rand, FIRST_NAMES);
}
export function pickLast(rand: () => number): string {
    return pickOne(rand, LAST_NAMES);
}

export function makeEmail(rand: () => number, first: string, last: string): string {
    const handle = (first + '.' + last).toLowerCase().replace(/[^a-z0-9.]/g, '');
    const domain = pickOne(rand, ['example.test', 'northgate-demo.test']);
    return `${handle}@${domain}`;
}

export function makePhone(rand: () => number): string {
    return pickPhoneRand(rand);
}

export function makePostal(rand: () => number, fsaPrefix: string): string {
    const first = (10 + Math.floor(rand() * 89)).toString();
    const second = (10 + Math.floor(rand() * 89)).toString();
    return `${fsaPrefix} ${first}${second}`;
}

export function makeStreet(rand: () => number): string {
    const num = (100 + Math.floor(rand() * 9899)).toString();
    const street = pickOne(rand, STREETS);
    const suffix = pickOne(rand, STREET_SUFFIXES);
    return `${num} ${street} ${suffix}`;
}

export function makeCity(rand: () => number): string {
    return pickOne(rand, ONTARIO_CITIES);
}

export function makeProvince(_rand: () => number): string {
    return 'ON';
}
