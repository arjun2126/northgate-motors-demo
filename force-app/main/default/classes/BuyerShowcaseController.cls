/**
 * Read-only buyer showcase data. No DML, no pricing engine, no invented inventory.
 * Public catalogue: server-mediated SYSTEM_MODE query limited to public statuses and
 * whitelisted fields. No native Vehicle/Model grant is issued to the buyer persona.
 */
// Public catalogue DTO. Secure guest-user record access blocks the system-mode query in a
// `with sharing` class; the public read runs without sharing, restricted to a status allowlist
// and field whitelist. No native Vehicle/Model permission is granted to the guest.
public without sharing class BuyerShowcaseController {
    private static final Set<String> PUBLIC_STATUSES = new Set<String>{'Available', 'In_Transit', 'Reserved'};
    private static final String IMAGE_PATTERN = '/resource/NG_VehicleImages/[a-z0-9_]+\\.webp';

    public class Choice {
        @AuraEnabled public String label;
        @AuraEnabled public String value;
        public Choice(String label, String value) { this.label = label; this.value = value; }
    }

    public class Model {
        @AuraEnabled public Id id;
        @AuraEnabled public String title;
        @AuraEnabled public String make;
        @AuraEnabled public String model;
        @AuraEnabled public String trim;
        @AuraEnabled public String bodyStyle;
        @AuraEnabled public String drivetrain;
        @AuraEnabled public String transmission;
        @AuraEnabled public String fuelType;
        @AuraEnabled public String imageName;
        @AuraEnabled public Decimal fromPrice;
        @AuraEnabled public Integer availableCount;
        @AuraEnabled public Integer inventoryCount;
    }

    public class Vehicle {
        @AuraEnabled public Id id;
        @AuraEnabled public Id modelId;
        @AuraEnabled public String stockNumber;
        @AuraEnabled public String title;
        @AuraEnabled public String modelTitle;
        @AuraEnabled public String colour;
        @AuraEnabled public String conditionLabel;
        @AuraEnabled public String bodyStyle;
        @AuraEnabled public String status;
        @AuraEnabled public String statusLabel;
        @AuraEnabled public String imageName;
        @AuraEnabled public Integer year;
        @AuraEnabled public Integer odometer;
        @AuraEnabled public Decimal price;
        @AuraEnabled public Boolean available;
    }

    public class Showcase {
        @AuraEnabled public List<Model> models = new List<Model>();
        @AuraEnabled public List<Vehicle> vehicles = new List<Vehicle>();
        @AuraEnabled public List<Choice> bodyStyles = new List<Choice>();
        @AuraEnabled public List<Choice> colours = new List<Choice>();
        @AuraEnabled public List<Choice> conditions = new List<Choice>();
        @AuraEnabled public Decimal maxPrice;
        @AuraEnabled public Integer availableCount = 0;
    }

    @AuraEnabled
    public static Showcase getShowcase() {
        Showcase result = new Showcase();
        List<Vehicle_Model__c> modelRows;
        List<Vehicle__c> vehicleRows;
        try {
            modelRows = [SELECT Id, Make__c, Model__c, Trim__c, Body_Style__c, Drivetrain__c,
                    Transmission__c, Fuel_Type__c, Image_Path__c
                FROM Vehicle_Model__c WHERE Is_Active__c = true
                WITH SYSTEM_MODE ORDER BY Make__c, Model__c];
            vehicleRows = [SELECT Id, Name, Year__c, Colour__c, Condition__c, Status__c,
                    List_Price__c, Odometer__c, Vehicle_Model__c,
                    Vehicle_Model__r.Make__c, Vehicle_Model__r.Model__c, Vehicle_Model__r.Trim__c,
                    Vehicle_Model__r.Body_Style__c, Vehicle_Model__r.Drivetrain__c,
                    Vehicle_Model__r.Transmission__c, Vehicle_Model__r.Fuel_Type__c,
                    Vehicle_Model__r.Image_Path__c
                FROM Vehicle__c WHERE Status__c IN :PUBLIC_STATUSES
                WITH SYSTEM_MODE ORDER BY List_Price__c ASC NULLS LAST LIMIT 200];
        } catch (System.QueryException error) {
            throw new AuraHandledException('Inventory is unavailable. Refresh and try again.');
        } catch (System.NoAccessException error) {
            throw new AuraHandledException('Inventory access is unavailable for this session.');
        }
        Map<Id, Model> modelsById = new Map<Id, Model>();
        for (Vehicle_Model__c row : modelRows) {
            Model model = new Model();
            model.id = row.Id; model.make = row.Make__c; model.model = row.Model__c; model.trim = row.Trim__c;
            model.bodyStyle = row.Body_Style__c; model.drivetrain = row.Drivetrain__c;
            model.transmission = row.Transmission__c; model.fuelType = row.Fuel_Type__c;
            model.title = modelTitle(row);
            model.imageName = safeImageName(row.Image_Path__c);
            model.availableCount = 0; model.inventoryCount = 0;
            result.models.add(model); modelsById.put(model.id, model);
        }
        Set<String> bodies = new Set<String>(), colours = new Set<String>(), conditions = new Set<String>();
        Decimal maxPrice = null;
        for (Vehicle__c row : vehicleRows) {
            Model model = modelsById.get(row.Vehicle_Model__c);
            if (model == null) continue;
            Vehicle vehicle = new Vehicle();
            vehicle.id = row.Id; vehicle.modelId = row.Vehicle_Model__c; vehicle.stockNumber = row.Name;
            vehicle.colour = row.Colour__c;
            vehicle.conditionLabel = label(row.Condition__c);
            vehicle.bodyStyle = model.bodyStyle;
            vehicle.status = row.Status__c; vehicle.statusLabel = statusLabel(row.Status__c);
            vehicle.year = row.Year__c == null ? null : row.Year__c.intValue();
            vehicle.odometer = row.Odometer__c == null ? null : row.Odometer__c.intValue();
            vehicle.price = row.List_Price__c; vehicle.available = row.Status__c == 'Available';
            vehicle.modelTitle = model.title;
            vehicle.title = vehicle.year == null ? model.title : vehicle.year + ' ' + model.title;
            vehicle.imageName = model.imageName;
            result.vehicles.add(vehicle);
            model.inventoryCount++;
            if (vehicle.available) {
                model.availableCount++;
                if (vehicle.price != null && (model.fromPrice == null || vehicle.price < model.fromPrice)) model.fromPrice = vehicle.price;
            }
            if (vehicle.available) result.availableCount++;
            if (String.isNotBlank(row.Colour__c)) colours.add(row.Colour__c);
            if (String.isNotBlank(model.bodyStyle)) bodies.add(model.bodyStyle);
            if (String.isNotBlank(vehicle.conditionLabel)) conditions.add(vehicle.conditionLabel);
            if (vehicle.price != null && (maxPrice == null || vehicle.price > maxPrice)) maxPrice = vehicle.price;
        }
        for (String value : sorted(bodies)) result.bodyStyles.add(new Choice(value, value));
        for (String value : sorted(colours)) result.colours.add(new Choice(value, value));
        for (String value : sorted(conditions)) result.conditions.add(new Choice(value, value));
        result.maxPrice = maxPrice == null ? 0 : maxPrice;
        return result;
    }

    private static String modelTitle(Vehicle_Model__c row) {
        String make = trimToEmpty(row.Make__c), model = trimToEmpty(row.Model__c), trim = trimToEmpty(row.Trim__c);
        List<String> parts = new List<String>();
        if (String.isNotBlank(make) && (String.isBlank(model) || !model.toLowerCase().startsWith(make.toLowerCase()))) parts.add(make);
        if (String.isNotBlank(model)) parts.add(model);
        if (String.isNotBlank(trim) && (String.isBlank(model) || !model.toLowerCase().endsWith(trim.toLowerCase()))) parts.add(trim);
        return parts.isEmpty() ? 'Northgate vehicle' : String.join(parts, ' ');
    }

    private static String safeImageName(String path) {
        if (String.isBlank(path) || !Pattern.matches(IMAGE_PATTERN, path)) return null;
        Integer slash = path.lastIndexOf('/');
        return slash >= 0 ? path.substring(slash + 1) : path;
    }

    private static String trimToEmpty(String value) { return value == null ? '' : value.trim(); }

    private static String label(String value) {
        if (String.isBlank(value)) return '';
        return value.replace('_', ' ');
    }

    private static String statusLabel(String value) {
        if (value == 'In_Transit') return 'In transit';
        return label(value);
    }

    private static List<String> sorted(Set<String> values) {
        List<String> rows = new List<String>(values);
        rows.sort();
        return rows;
    }
}
