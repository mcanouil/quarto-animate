Reveal.addEventListener('slidechanged', function (event) {
  const animatedElements = event.currentSlide.querySelectorAll('.animate__animated');
  animatedElements.forEach(element => {
    const animationClass = Array.from(element.classList).find(cls => cls.startsWith('animate__') && cls !== 'animate__animated');
    if (animationClass) {
      element.classList.remove(animationClass);
      void element.offsetWidth;
      element.classList.add(animationClass);
    }
  });
});
