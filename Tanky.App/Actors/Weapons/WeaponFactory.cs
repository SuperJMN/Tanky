using System;
using SuperJMN.MonoGame;
using Tanky.App.Actors.Shots;

namespace Tanky.App.Actors.Weapons
{
    public abstract class WeaponFactory
    {
        public abstract Shot CreateShot(IStageObject shooter);
        public abstract TimeSpan ShootingRate { get; }
    }
}