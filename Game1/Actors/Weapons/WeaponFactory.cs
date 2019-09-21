using System;
using Tanky.Actors.Shots;

namespace Tanky.Actors.Weapons
{
    public abstract class WeaponFactory
    {
        public abstract Shot CreateShot();
        public abstract TimeSpan ShootingRate { get; }
    }
}