using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Audio;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;
using SuperJMN.MonoGame;

namespace Tanky.Actors.Shots
{
    internal class RegularShot : Shot
    {
        private static Texture2D texture;

        public RegularShot()
        {
            Width = 10;
            Height = 10;
            HorizontalSpeed = 300;
        }

        public override void Draw(SpriteBatch spriteBatch)
        {
            var sourceRectangle = new Rectangle(0, 0, texture.Width, texture.Height);
            spriteBatch.Draw(texture, Bounds, sourceRectangle, Color.White);
        }

        public override void LoadContent(ContentManager content)
        {
            texture = content.Load<Texture2D>("Shot");
            ShootSound = content.Load<SoundEffect>("sounds/shoot");
        }

        public override void Update(GameTime gameTime)
        {
            Left += HorizontalSpeed.Apply(gameTime);
            if (this.IsOutOfBounds())
            {
                Dispose();
            }
        }

        private void Destroy()
        {
            Stage.Remove(this);
        }

        private void Dispose()
        {
            Stage.Remove(this);
        }

        public override int Damage { get; } = 5;
        public override int HealthPoints { get; set; } = 50;
    }
}