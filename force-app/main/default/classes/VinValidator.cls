public class VinValidator {
    private static final Map<String, Integer> TRANSLITERATION = new Map<String, Integer>{
        'A' => 1, 'B' => 2, 'C' => 3, 'D' => 4, 'E' => 5, 'F' => 6, 'G' => 7, 'H' => 8,
        'J' => 1, 'K' => 2, 'L' => 3, 'M' => 4, 'N' => 5, 'P' => 7, 'R' => 9,
        'S' => 2, 'T' => 3, 'U' => 4, 'V' => 5, 'W' => 6, 'X' => 7, 'Y' => 8, 'Z' => 9
    };
    private static final List<Integer> WEIGHTS = new List<Integer>{8,7,6,5,4,3,2,10,0,9,8,7,6,5,4,3,2};

    public static Boolean isValid(String vin) {
        if (String.isBlank(vin) || vin.length() != 17) return false;
        Integer total = 0;
        for (Integer i = 0; i < 17; i++) {
            if (i == 8) continue; // check digit position
            String ch = vin.substring(i, i + 1).toUpperCase();
            Integer value;
            if (ch.isNumeric()) {
                value = Integer.valueOf(ch);
            } else {
                if (!TRANSLITERATION.containsKey(ch)) return false;
                value = TRANSLITERATION.get(ch);
            }
            total += value * WEIGHTS[i];
        }
        Integer remainder = Math.mod(total, 11);
        String expected = (remainder == 10) ? 'X' : String.valueOf(remainder);
        return vin.substring(8, 9).toUpperCase() == expected;
    }
}
