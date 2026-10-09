package com.ynov.dogs.dog;

import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

@Service
public class DogService {

    private final DogRepository dogRepository;

    public DogService(DogRepository dogRepository) {
        this.dogRepository = dogRepository;
    }

    public List<Dog> findAll() {
        return dogRepository.findAll();
    }

    public Dog findById(Long id) {
        return dogRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Dog not found"));
    }

    public Dog create(Dog dog) {
        dog.setId(null);
        return dogRepository.save(dog);
    }

    public Dog update(Long id, Dog dog) {
        Dog existing = findById(id);
        existing.setName(dog.getName());
        existing.setBirthDate(dog.getBirthDate());
        existing.setBreed(dog.getBreed());
        existing.setSterilized(dog.isSterilized());
        return dogRepository.save(existing);
    }

    public void delete(Long id) {
        if (!dogRepository.existsById(id)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Dog not found");
        }
        dogRepository.deleteById(id);
    }
}
