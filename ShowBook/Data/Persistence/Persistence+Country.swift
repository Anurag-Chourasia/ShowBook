import CoreData

extension PersistenceController {
    func saveCountryModel(_ countryModel: CountryModel) {
        let context = container.viewContext
        let countryEntity = CountryEntity(context: context)
        countryEntity.status = countryModel.status
        countryEntity.statusCode = Int16(countryModel.statusCode)
        countryEntity.version = countryModel.version
        countryEntity.access = countryModel.access
        countryEntity.total = Int16(countryModel.total)
        countryEntity.offset = Int16(countryModel.offset)
        countryEntity.limit = Int16(countryModel.limit)

        for (_, datum) in countryModel.data {
            let datumEntity = DatumEntity(context: context)
            datumEntity.country = datum.country

            let regionEntity = RegionEntity(context: context)
            regionEntity.region = datum.region.rawValue

            datumEntity.region = regionEntity
            countryEntity.addToData(datumEntity)
        }
        saveContext()
    }

    func saveDefaultCountryName(selectedCountryName: String) {
        let context = container.viewContext
        do {
            let fetchRequest: NSFetchRequest<CountryEntity> = CountryEntity.fetchRequest()
            let countryEntities = try context.fetch(fetchRequest)

            if let existingCountryEntity = countryEntities.first {
                existingCountryEntity.selectedCountryName = selectedCountryName
            } else {
                let newCountryEntity = CountryEntity(context: context)
                newCountryEntity.selectedCountryName = selectedCountryName
            }

            let prefRequest: NSFetchRequest<UserPreference> = UserPreference.fetchRequest()
            let prefEntities = try context.fetch(prefRequest)
            let pref = prefEntities.first ?? UserPreference(context: context)
            pref.selectedCountryName = selectedCountryName
            if let uuid = currentUserUUID {
                pref.userUUID = uuid
                pref.ownerID = uuid.uuidString.lowercased()
            }
            saveContext()
        } catch {
            persistenceLogger.log("Error saving default country name: \(error)", level: .error)
        }
    }

    func fetchSelectedCountryName() -> String? {
        let context = container.viewContext
        do {
            let prefRequest: NSFetchRequest<UserPreference> = UserPreference.fetchRequest()
            if let pref = try context.fetch(prefRequest).first,
               let country = pref.selectedCountryName, !country.isEmpty {
                return country
            }

            let fetchRequest: NSFetchRequest<CountryEntity> = CountryEntity.fetchRequest()
            let countryEntities = try context.fetch(fetchRequest)
            guard let firstCountryEntity = countryEntities.first else {
                persistenceLogger.log("No CountryEntity found", level: .info)
                return nil
            }
            return firstCountryEntity.selectedCountryName
        } catch {
            persistenceLogger.log("Error fetching selected country name: \(error)", level: .error)
            return nil
        }
    }

    func fetchCountryModel() -> CountryModel? {
        let context = container.viewContext
        do {
            let fetchRequest: NSFetchRequest<CountryEntity> = CountryEntity.fetchRequest()
            let countryEntities = try context.fetch(fetchRequest)
            guard let firstCountryEntity = countryEntities.first else { return nil }

            var data: [String: Datum] = [:]
            firstCountryEntity.data?.forEach { datumEntity in
                if let datum = datumEntity as? DatumEntity {
                    let regionEnum = Region(rawValue: datum.region?.region ?? Region.africa.rawValue)
                    data[datum.country ?? ""] = Datum(country: datum.country ?? "", region: regionEnum)
                }
            }

            return CountryModel(
                status: firstCountryEntity.status ?? "",
                statusCode: Int(firstCountryEntity.statusCode),
                version: firstCountryEntity.version ?? "",
                access: firstCountryEntity.access ?? "",
                total: Int(firstCountryEntity.total),
                offset: Int(firstCountryEntity.offset),
                limit: Int(firstCountryEntity.limit),
                data: data
            )
        } catch {
            persistenceLogger.log("Error fetching CountryModel: \(error)", level: .error)
            return nil
        }
    }
}
