package com.ynov.crud.dog;

import com.ynov.crud.log.LogLevel;
import com.ynov.crud.log.LogsClient;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

@Service
public class DogService {

    private final DogRepository dogRepository;
    private final LogsClient logsClient;

    public DogService(DogRepository dogRepository, LogsClient logsClient) {
        this.dogRepository = dogRepository;
        this.logsClient = logsClient;
    }

    public List<Dog> findAll() {
        List<Dog> dogs = dogRepository.findAll();
        logsClient.send("Listed " + dogs.size() + " dogs", "GET", "/api/v1/dogs", LogLevel.INFO);
        return dogs;
    }

    public Dog findById(Long id) {
        return dogRepository.findById(id).orElseThrow(() -> {
            logsClient.send("Dog not found: " + id, "GET", "/api/v1/dogs/" + id, LogLevel.ERR);
            return new ResponseStatusException(HttpStatus.NOT_FOUND, "Dog not found");
        });
    }

    public Dog create(Dog dog) {
        dog.setId(null);
        Dog saved = dogRepository.save(dog);
        logsClient.send("Created dog id=" + saved.getId(), "POST", "/api/v1/dogs", LogLevel.INFO);
        return saved;
    }

    public Dog update(Long id, Dog dog) {
        Dog existing = dogRepository.findById(id).orElseThrow(() -> {
            logsClient.send("Dog not found: " + id, "PUT", "/api/v1/dogs/" + id, LogLevel.ERR);
            return new ResponseStatusException(HttpStatus.NOT_FOUND, "Dog not found");
        });
        existing.setName(dog.getName());
        existing.setBirthDate(dog.getBirthDate());
        existing.setBreed(dog.getBreed());
        existing.setSterilized(dog.isSterilized());
        Dog saved = dogRepository.save(existing);
        logsClient.send("Updated dog id=" + id, "PUT", "/api/v1/dogs/" + id, LogLevel.INFO);
        return saved;
    }

    public void delete(Long id) {
        if (!dogRepository.existsById(id)) {
            logsClient.send("Dog not found: " + id, "DELETE", "/api/v1/dogs/" + id, LogLevel.ERR);
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Dog not found");
        }
        dogRepository.deleteById(id);
        logsClient.send("Deleted dog id=" + id, "DELETE", "/api/v1/dogs/" + id, LogLevel.WARN);
    }
}
