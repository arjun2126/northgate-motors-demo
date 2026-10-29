/**
 * ISO 3779 VIN generation and validation.
 * WMI = "NGD" (invented). VDS = deterministic from PRNG. Check digit (position 9)
 * uses the standard transliteration + weights + mod-11.
 * Charset excludes I, O, Q.
 */

const VIN_CHARS = 'ABCDEFGHJKLMNPRSTUVWXYZ0123456789';
const VIN_CHARS_NO_DIGIT = 'ABCDEFGHJKLMNPRSTUVWXYZ';

function vinValue(c: string): number | undefined {
    switch (c) {
        case 'A': return 1; case 'B': return 2; case 'C': return 3; case 'D': return 4;
        case 'E': return 5; case 'F': return 6; case 'G': return 7; case 'H': return 8;
        case 'J': return 1; case 'K': return 2; case 'L': return 3; case 'M': return 4;
        case 'N': return 5; case 'P': return 7; case 'R': return 9;
        case 'S': return 2; case 'T': return 3; case 'U': return 4; case 'V': return 5;
        case 'W': return 6; case 'X': return 7; case 'Y': return 8; case 'Z': return 9;
        case '0': return 0; case '1': return 1; case '2': return 2; case '3': return 3;
        case '4': return 4; case '5': return 5; case '6': return 6; case '7': return 7;
        case '8': return 8; case '9': return 9;
        default: return undefined;
    }
}

const VIN_WEIGHTS = [8, 7, 6, 5, 4, 3, 2, 10, 0, 9, 8, 7, 6, 5, 4, 3, 2];

const MODEL_YEAR_TABLE: Array<[number, string]> = [
    [2010, 'A'], [2011, 'B'], [2012, 'C'], [2013, 'D'], [2014, 'E'], [2015, 'F'],
    [2016, 'G'], [2017, 'H'], [2018, 'J'], [2019, 'K'], [2020, 'L'], [2021, 'M'],
    [2022, 'N'], [2023, 'P'], [2024, 'R'], [2025, 'S'], [2026, 'T'], [2027, 'V'],
];

function modelYearCode(year: number): string {
    for (const [y, c] of MODEL_YEAR_TABLE) if (y === year) return c;
    // Fallback (should not trigger with our 2010-2027 range)
    return 'T';
}

function plantCode(_rand: () => number): string {
    // Single plant character; deterministic pick of 'A' for now (avoids a noisy RNG branch).
    return 'A';
}

function serialCode(rand: () => number): string {
    // 6 chars from the VIN charset, deterministic.
    let out = '';
    for (let i = 0; i < 6; i++) {
        out += VIN_CHARS.charAt(Math.floor(rand() * VIN_CHARS.length));
    }
    return out;
}

function vds(rand: () => number): string {
    // 6 chars: VDS excludes I, O, Q; deterministic.
    let out = '';
    for (let i = 0; i < 6; i++) {
        out += VIN_CHARS_NO_DIGIT.charAt(Math.floor(rand() * VIN_CHARS_NO_DIGIT.length));
    }
    return out;
}

function checkDigit(vin: string): string {
    // ISO 3779: weighted sum over positions 1-8 and 10-17 (position 9 is the check
    // digit, weight 0). The check digit value is sum % 11 ('X' for 10). Validation
    // recomputes the same sum and checks the digit matches.
    let sumOthers = 0;
    for (let i = 0; i < vin.length; i++) {
        if (i === 8) continue; // check digit position
        const v = vinValue(vin[i]!) ?? 0;
        sumOthers += v * VIN_WEIGHTS[i]!;
    }
    const cd = sumOthers % 11;
    return cd === 10 ? 'X' : String(cd);
}

export function makeVin(rand: () => number, modelYear: string): string {
    const year = parseInt(modelYear, 10) || 2024;
    const wmi = 'NGD';
    const v = vds(rand);
    const yearChar = modelYearCode(year);
    const plant = plantCode(rand);
    const serial = serialCode(rand);
    const partial = `${wmi}${v}${yearChar}${plant}${serial}`; // 3+6+1+1+6 = 17 (check digit will replace v[5])
    const cd = checkDigit(partial);
    // The check digit is at position 9 (1-indexed) of the 17-char VIN → index 8.
    return partial.slice(0, 8) + cd + partial.slice(9);
}

export function vinValid(vin: string): boolean {
    if (vin.length !== 17) return false;
    for (const c of vin) {
        if (vinValue(c) === undefined) return false;
    }
    // ISO 3779: position 9 is the check digit (weight 0). Recompute the weighted sum
    // treating position 9 as 0; the remainder mod 11 must equal the check-digit
    // character at position 9 ('X' = 10).
    let sum = 0;
    for (let i = 0; i < 17; i++) {
        if (i === 8) continue; // skip check digit position
        const v = vinValue(vin[i]!) ?? 0;
        sum += v * VIN_WEIGHTS[i]!;
    }
    const expected = sum % 11;
    const actual = vin[8] === 'X' ? 10 : (vinValue(vin[8]!) ?? -1);
    return actual === expected;
}
